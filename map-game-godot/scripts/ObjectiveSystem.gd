extends Node3D

@export var player_path: NodePath = NodePath("../Player")
@export var start_time_seconds: float = 90.0
@export var checkpoint_time_bonus_seconds: float = 12.0
@export var checkpoint_points: int = 100
@export var checkpoint_spawn_range: float = 200.0
@export var checkpoint_min_distance: float = 40.0
@export var checkpoint_radius: float = 9.0
@export var checkpoint_height: float = 120.0
@export var checkpoint_ground_embed_depth: float = 3.0
@export var max_spawn_attempts: int = 24
@export var world_border_radius: float = 200.0
@export_flags_3d_physics var ground_collision_mask: int = 1
@export var ground_probe_height: float = 500.0
@export var main_menu_scene_path: String = "res://main_menu.tscn"
@export var objective_hud_scene: PackedScene = preload("res://ui/objective_hud.tscn")
@export var compass_half_fov_degrees: float = 90.0
@export var compass_bar_width: float = 220.0
@export var compass_bar_height: float = 14.0

var _player: CharacterBody3D
var _time_remaining: float = 0.0
var _score: int = 0
var _high_score: int = 0
var _game_over: bool = false

var _spawn_origin: Vector3 = Vector3.ZERO
var _spawn_ground_origin: Vector3 = Vector3.ZERO
var _spawn_right: Vector3 = Vector3.RIGHT
var _spawn_forward: Vector3 = Vector3.FORWARD
var _spawn_up: Vector3 = Vector3.UP
var _world_origin: Vector3 = Vector3.ZERO
var _world_up: Vector3 = Vector3.UP

var _checkpoint_root: Node3D
var _hud_layer: CanvasLayer
var _hud_label: Label
var _compass_root: Control
var _compass_target_marker: ColorRect
var _compass_center_marker: ColorRect
var _game_over_panel: PanelContainer
var _game_over_title: Label
var _game_over_score: Label
var _is_transitioning: bool = false
var _upright_sync_frames: int = 0

func _ready() -> void:
	randomize()
	_player = get_node_or_null(player_path) as CharacterBody3D
	if _player == null:
		set_process(false)
		return

	_update_spawn_frame_from_player()
	_world_origin = _spawn_ground_origin
	_world_up = _spawn_up

	_time_remaining = start_time_seconds
	_high_score = _get_current_high_score()
	_create_hud()
	_spawn_checkpoint()
	_upright_sync_frames = 8
	_update_hud()

func _game_state() -> Node:
	return get_node_or_null("/root/GameState")

func _get_current_high_score() -> int:
	var state := _game_state()
	if state == null or not state.has_method("get_high_score"):
		return 0
	return int(state.get_high_score())

func _submit_high_score_if_needed() -> void:
	if _score <= _high_score:
		return
	var state := _game_state()
	if state == null or not state.has_method("submit_score"):
		_high_score = _score
		return
	state.submit_score(_score)
	_high_score = maxi(_high_score, _score)

func _process(delta: float) -> void:
	if _upright_sync_frames > 0:
		_sync_checkpoint_upright_from_player(true)
		_upright_sync_frames -= 1

	if _game_over:
		_update_hud()
		return
	if _player == null:
		return
	if not _player.is_physics_processing():
		_update_hud()
		return

	_time_remaining = maxf(_time_remaining - delta, 0.0)
	if _time_remaining <= 0.0:
		_set_game_over(true)
	_update_compass()
	_update_hud()

func _safe_normalized(v: Vector3, fallback: Vector3) -> Vector3:
	if not v.is_finite() or v.length_squared() < 0.000001:
		return fallback
	return v.normalized()

func _sync_checkpoint_upright_from_player(reorient_existing: bool) -> void:
	if _player == null:
		return
	_update_spawn_frame_from_player()
	_world_up = _spawn_up
	if reorient_existing and _checkpoint_root != null:
		var checkpoint_pos := _checkpoint_root.global_position
		var clamped_pos := _clamp_planar_to_world_border(checkpoint_pos)
		var grounded_pos := _snap_checkpoint_ground_to_surface(clamped_pos)
		if grounded_pos.is_finite():
			checkpoint_pos = grounded_pos
		var checkpoint_basis := Basis(_spawn_right, _spawn_up, _spawn_forward).orthonormalized()
		_checkpoint_root.global_transform = Transform3D(checkpoint_basis, checkpoint_pos)

func _create_hud() -> void:
	if objective_hud_scene != null:
		var hud_instance := objective_hud_scene.instantiate()
		if hud_instance is CanvasLayer:
			_hud_layer = hud_instance as CanvasLayer
			add_child(_hud_layer)

	if _hud_layer == null:
		_hud_layer = CanvasLayer.new()
		_hud_layer.layer = 120
		add_child(_hud_layer)

	_hud_label = _hud_layer.get_node_or_null("HudLabel") as Label
	if _hud_label == null:
		_hud_label = Label.new()
		_hud_label.position = Vector2(12, 12)
		_hud_label.add_theme_font_size_override("font_size", 18)
		_hud_layer.add_child(_hud_label)

	_game_over_panel = _hud_layer.get_node_or_null("GameOverPanel") as PanelContainer
	_game_over_title = _hud_layer.get_node_or_null("GameOverPanel/MarginContainer/VBoxContainer/TitleLabel") as Label
	_game_over_score = _hud_layer.get_node_or_null("GameOverPanel/MarginContainer/VBoxContainer/ScoreLabel") as Label
	var restart_button := _hud_layer.get_node_or_null("GameOverPanel/MarginContainer/VBoxContainer/RestartButton") as Button
	var menu_button := _hud_layer.get_node_or_null("GameOverPanel/MarginContainer/VBoxContainer/MainMenuButton") as Button

	if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button and not menu_button.pressed.is_connected(_on_main_menu_pressed):
		menu_button.pressed.connect(_on_main_menu_pressed)

	if _game_over_panel == null:
		_create_game_over_ui()

	_create_compass_ui_if_needed()

func _create_game_over_ui() -> void:
	_game_over_panel = PanelContainer.new()
	_game_over_panel.visible = false
	_game_over_panel.set_anchors_preset(Control.PRESET_CENTER)
	_game_over_panel.custom_minimum_size = Vector2(360, 180)
	_hud_layer.add_child(_game_over_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	_game_over_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_game_over_title = Label.new()
	_game_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_title.add_theme_font_size_override("font_size", 24)
	_game_over_title.text = "Game Over"
	vbox.add_child(_game_over_title)

	_game_over_score = Label.new()
	_game_over_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_score.text = "Score: 0"
	vbox.add_child(_game_over_score)

	var restart_button := Button.new()
	restart_button.text = "Restart"
	restart_button.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_button)

	var menu_button := Button.new()
	menu_button.text = "Main Menu"
	menu_button.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(menu_button)

func _update_hud() -> void:
	if _hud_label == null:
		return

	var checkpoint_line := _get_checkpoint_indicator_text()
	if _game_over:
		_hud_label.text = "Time: 0.0\nScore: %d\nBest: %d\nObjective failed\n%s" % [_score, _high_score, checkpoint_line]
	else:
		_hud_label.text = "Time: %.1f\nScore: %d\nBest: %d\n%s" % [_time_remaining, _score, _high_score, checkpoint_line]

	if _game_over_score:
		_game_over_score.text = "Score: %d" % _score

func _create_compass_ui_if_needed() -> void:
	if _hud_layer == null or _compass_root != null:
		return

	_compass_root = Control.new()
	_compass_root.name = "CheckpointCompass"
	_compass_root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_compass_root.offset_top = 10.0
	_compass_root.offset_bottom = 38.0
	_compass_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_compass_root)

	var bar_bg := ColorRect.new()
	bar_bg.name = "CompassBarBg"
	bar_bg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bar_bg.offset_left = -compass_bar_width * 0.5
	bar_bg.offset_right = compass_bar_width * 0.5
	bar_bg.offset_top = 10.0
	bar_bg.offset_bottom = 10.0 + compass_bar_height
	bar_bg.color = Color(0.05, 0.08, 0.11, 0.58)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compass_root.add_child(bar_bg)

	_compass_center_marker = ColorRect.new()
	_compass_center_marker.name = "CompassCenterMarker"
	_compass_center_marker.set_anchors_preset(Control.PRESET_CENTER)
	_compass_center_marker.offset_left = -1.0
	_compass_center_marker.offset_right = 1.0
	_compass_center_marker.offset_top = -5.0
	_compass_center_marker.offset_bottom = 5.0
	_compass_center_marker.color = Color(0.9, 0.95, 1.0, 0.95)
	bar_bg.add_child(_compass_center_marker)

	_compass_target_marker = ColorRect.new()
	_compass_target_marker.name = "CompassTargetMarker"
	_compass_target_marker.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_compass_target_marker.offset_left = -3.0
	_compass_target_marker.offset_right = 3.0
	_compass_target_marker.offset_top = -6.0
	_compass_target_marker.offset_bottom = 6.0
	_compass_target_marker.position = Vector2(compass_bar_width * 0.5, compass_bar_height * 0.5)
	_compass_target_marker.color = Color(0.2, 0.95, 1.0, 0.95)
	bar_bg.add_child(_compass_target_marker)

func _update_compass() -> void:
	if _compass_root == null or _compass_target_marker == null:
		return

	if _player == null or _checkpoint_root == null or _game_over:
		_compass_root.visible = false
		return

	var checkpoint_center := _checkpoint_root.global_position + _checkpoint_root.global_basis.y * _get_checkpoint_vertical_offset()
	var to_checkpoint := checkpoint_center - _player.global_position
	if not to_checkpoint.is_finite() or to_checkpoint.length_squared() < 0.0001:
		_compass_root.visible = false
		return

	var up := _safe_normalized(_player.up_direction, Vector3.UP)
	var right := _safe_normalized(_player.global_basis.x - up * _player.global_basis.x.dot(up), Vector3.RIGHT)
	var forward := _safe_normalized(-(_player.global_basis.z - up * _player.global_basis.z.dot(up)), Vector3.FORWARD)
	var planar_dir := to_checkpoint - up * to_checkpoint.dot(up)
	if planar_dir.length_squared() < 0.0001:
		_compass_root.visible = false
		return

	_compass_root.visible = true
	planar_dir = planar_dir.normalized()
	var side := planar_dir.dot(right)
	var fwd := planar_dir.dot(forward)
	var angle := atan2(side, fwd)
	var half_fov_rad := deg_to_rad(maxf(compass_half_fov_degrees, 1.0))
	var normalized := clampf(angle / half_fov_rad, -1.0, 1.0)

	var half_w := compass_bar_width * 0.5
	_compass_target_marker.position.x = half_w + normalized * half_w

	var frontness := clampf(fwd, -1.0, 1.0)
	var strength := clampf(frontness * 0.5 + 0.5, 0.25, 1.0)
	_compass_target_marker.color = Color(0.2, 0.95, 1.0, lerpf(0.45, 0.98, strength))

func _set_game_over(active: bool) -> void:
	if active:
		_submit_high_score_if_needed()
	_game_over = active
	_set_player_locked(active)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if active else Input.MOUSE_MODE_CAPTURED
	if _game_over_panel:
		_game_over_panel.visible = active

func _set_player_locked(locked: bool) -> void:
	if _player == null:
		return
	_player.set_process(not locked)
	_player.set_physics_process(not locked)
	_player.set_process_input(not locked)

func _on_restart_pressed() -> void:
	if get_tree() == null or _is_transitioning:
		return
	_is_transitioning = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var state := get_node_or_null("/root/GameState")
	if state and state.has_method("get"):
		state.show_world_loading_overlay = false
	Input.flush_buffered_events()
	call_deferred("_deferred_change_scene", "res://node_3d.tscn")

func _on_main_menu_pressed() -> void:
	if get_tree() == null or _is_transitioning:
		return
	_is_transitioning = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Input.flush_buffered_events()
	call_deferred("_deferred_change_scene", main_menu_scene_path)

func _deferred_change_scene(scene_path: String) -> void:
	if get_tree() == null:
		_is_transitioning = false
		return
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		_is_transitioning = false

func _get_checkpoint_indicator_text() -> String:
	if _player == null or _checkpoint_root == null:
		return "Checkpoint: --"

	var checkpoint_center := _checkpoint_root.global_position + _checkpoint_root.global_basis.y * _get_checkpoint_vertical_offset()
	var to_checkpoint := checkpoint_center - _player.global_position
	if not to_checkpoint.is_finite() or to_checkpoint.length_squared() < 0.0001:
		return "Checkpoint: --"

	var up := _safe_normalized(_player.up_direction, Vector3.UP)
	var right := _safe_normalized(_player.global_basis.x - up * _player.global_basis.x.dot(up), Vector3.RIGHT)
	var forward := _safe_normalized(-( _player.global_basis.z - up * _player.global_basis.z.dot(up) ), Vector3.FORWARD)

	var planar := to_checkpoint - up * to_checkpoint.dot(up)
	var dist := to_checkpoint.length()
	if planar.length_squared() < 0.0001:
		return "Checkpoint: %.0fm ↑" % dist

	var dir := planar.normalized()
	var side := dir.dot(right)
	var fwd := dir.dot(forward)
	var arrow := "↑"
	if absf(side) > absf(fwd):
		arrow = "→" if side > 0.0 else "←"
	elif fwd < 0.0:
		arrow = "↓"

	return "Checkpoint: %.0fm %s" % [dist, arrow]

func _spawn_checkpoint() -> void:
	if _checkpoint_root != null:
		_checkpoint_root.queue_free()

	_update_spawn_frame_from_player()
	var checkpoint_pos := _find_checkpoint_ground_position()
	if not checkpoint_pos.is_finite():
		var emergency_ground := _snap_checkpoint_ground_to_surface(_world_origin)
		if emergency_ground.is_finite():
			checkpoint_pos = emergency_ground
		else:
			checkpoint_pos = _spawn_ground_origin if _spawn_ground_origin.is_finite() else _spawn_origin
	var checkpoint_basis := Basis(_spawn_right, _spawn_up, _spawn_forward).orthonormalized()
	var local_vertical_offset := _get_checkpoint_vertical_offset()

	_checkpoint_root = Node3D.new()
	_checkpoint_root.name = "Checkpoint"
	_checkpoint_root.global_transform = Transform3D(checkpoint_basis, checkpoint_pos)
	add_child(_checkpoint_root)

	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = checkpoint_radius
	mesh.bottom_radius = checkpoint_radius
	mesh.height = checkpoint_height
	mesh.radial_segments = 24
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3.UP * local_vertical_offset

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.2, 0.95, 1.0, 0.35)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = mat
	_checkpoint_root.add_child(mesh_instance)

	var area := Area3D.new()
	area.monitoring = true
	area.monitorable = true
	area.position = Vector3.UP * local_vertical_offset
	area.body_entered.connect(_on_checkpoint_body_entered)
	_checkpoint_root.add_child(area)

	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = checkpoint_radius * 0.85
	shape.height = checkpoint_height
	collision.shape = shape
	area.add_child(collision)

func _update_spawn_frame_from_player() -> void:
	if _player == null:
		return

	_spawn_origin = _player.global_position
	_spawn_up = _safe_normalized(_player.up_direction, _spawn_up)
	var grounded_spawn := _snap_checkpoint_ground_to_surface(_spawn_origin)
	if grounded_spawn.is_finite():
		_spawn_ground_origin = grounded_spawn
	else:
		_spawn_ground_origin = _spawn_origin

	var right_projected := _player.global_basis.x - _spawn_up * _player.global_basis.x.dot(_spawn_up)
	_spawn_right = _safe_normalized(right_projected, _spawn_right)

	var forward_projected := _player.global_basis.z - _spawn_up * _player.global_basis.z.dot(_spawn_up)
	_spawn_forward = _safe_normalized(forward_projected, _spawn_forward)

	if _spawn_right.length_squared() < 0.000001 or absf(_spawn_right.dot(_spawn_up)) > 0.99:
		var fallback_ref := Vector3.FORWARD if absf(_spawn_up.dot(Vector3.FORWARD)) < 0.99 else Vector3.RIGHT
		_spawn_right = _safe_normalized(_spawn_up.cross(fallback_ref), Vector3.RIGHT)

	_spawn_forward = _safe_normalized(_spawn_right.cross(_spawn_up), _spawn_forward)

func _get_checkpoint_vertical_offset() -> float:
	return maxf((checkpoint_height * 0.5) - checkpoint_ground_embed_depth, 0.0)

func _snap_checkpoint_ground_to_surface(planar_position: Vector3) -> Vector3:
	if get_world_3d() == null:
		return Vector3(INF, INF, INF)

	var base_cast_offset := maxf(ground_probe_height, checkpoint_height)
	var probe_scales := [1.0, 4.0, 12.0]
	for probe_scale in probe_scales:
		var cast_offset := base_cast_offset * float(probe_scale)
		var ray_start := planar_position + _spawn_up * cast_offset
		var ray_end := planar_position - _spawn_up * cast_offset

		var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		query.collision_mask = ground_collision_mask
		query.collide_with_bodies = true
		query.collide_with_areas = false
		query.exclude = [self]
		if _player != null:
			query.exclude.append(_player)
		if _checkpoint_root != null:
			query.exclude.append(_checkpoint_root)

		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue

		var hit_position: Vector3 = hit.position
		if not hit_position.is_finite():
			continue

		var hit_normal: Vector3 = hit.normal
		if hit_normal.is_finite() and hit_normal.length_squared() > 0.000001:
			var up_alignment := hit_normal.normalized().dot(_spawn_up)
			if up_alignment < 0.12:
				continue

		return hit_position

	return Vector3(INF, INF, INF)

func _is_within_world_border(point: Vector3) -> bool:
	var up := _safe_normalized(_world_up, Vector3.UP)
	var to_pos := point - _world_origin
	var planar := to_pos - up * to_pos.dot(up)
	var max_radius := maxf(world_border_radius - checkpoint_radius, 0.0)
	return planar.length() <= max_radius + 0.05

func _clamp_planar_to_world_border(planar_position: Vector3) -> Vector3:
	var up := _safe_normalized(_world_up, Vector3.UP)
	var to_pos := planar_position - _world_origin
	var vertical := up * to_pos.dot(up)
	var planar := to_pos - vertical
	var max_radius := maxf(world_border_radius - checkpoint_radius, 0.0)
	var planar_len := planar.length()
	if planar_len <= max_radius:
		return planar_position
	if planar_len < 0.0001:
		return _world_origin + vertical
	return _world_origin + vertical + (planar / planar_len) * max_radius

func _find_checkpoint_ground_position() -> Vector3:
	var base_origin := _spawn_ground_origin if _spawn_ground_origin.is_finite() else _spawn_origin
	for _attempt in range(max_spawn_attempts):
		var distance := randf_range(checkpoint_min_distance, checkpoint_spawn_range)
		var angle := randf_range(0.0, TAU)
		var planar_dir := _spawn_right * cos(angle) + _spawn_forward * sin(angle)
		var planar_pos := base_origin + planar_dir * distance
		planar_pos = _clamp_planar_to_world_border(planar_pos)
		var candidate := _snap_checkpoint_ground_to_surface(planar_pos)
		if not candidate.is_finite():
			continue
		var to_candidate := candidate - base_origin
		var planar_to_candidate := to_candidate - _spawn_up * to_candidate.dot(_spawn_up)
		var planar_distance := planar_to_candidate.length()
		if planar_distance <= checkpoint_spawn_range + 0.1 and _is_within_world_border(candidate) and planar_distance >= checkpoint_min_distance * 0.7:
			return candidate

	var fallback_planar := base_origin + _spawn_forward * checkpoint_min_distance
	fallback_planar = _clamp_planar_to_world_border(fallback_planar)
	var fallback_ground := _snap_checkpoint_ground_to_surface(fallback_planar)
	if fallback_ground.is_finite():
		return fallback_ground

	if _spawn_ground_origin.is_finite():
		return _spawn_ground_origin

	return Vector3(INF, INF, INF)

func _on_checkpoint_body_entered(body: Node) -> void:
	if _game_over:
		return
	if body != _player:
		return

	_score += checkpoint_points
	_submit_high_score_if_needed()
	_time_remaining += checkpoint_time_bonus_seconds
	_spawn_checkpoint()
	_update_hud()
