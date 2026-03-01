extends Node3D

enum GamePhase {
	LOADING,
	PLAYING,
	PAUSED,
	GAME_OVER,
	TRANSITIONING
}

@export var player_path: NodePath = NodePath("../Player")
@export var start_time_seconds: float = 90.0
@export var checkpoint_time_bonus_seconds: float = 12.0
@export var checkpoint_points: int = 100
@export var checkpoint_spawn_range: float = 200.0
@export var checkpoint_min_distance: float = 40.0
@export var checkpoint_radius: float = 9.0
@export var checkpoint_height: float = 120.0
@export var checkpoint_ground_embed_depth: float = 3.0
@export var checkpoint_border_margin: float = 10.0
@export var max_spawn_attempts: int = 24
@export var world_border_radius: float = 200.0
@export_flags_3d_physics var ground_collision_mask: int = 1
@export var ground_probe_height: float = 500.0
@export var main_menu_scene_path: String = "res://main_menu.tscn"
@export var world_scene_path: String = "res://node_3d.tscn"
@export var transition_bridge_scene_path: String = "res://transition_bridge.tscn"
@export var objective_hud_scene: PackedScene = preload("res://ui/objective_hud.tscn")
@export var compass_half_fov_degrees: float = 90.0
@export var compass_bar_width: float = 220.0
@export var compass_bar_height: float = 14.0
@export var hud_refresh_interval: float = 0.08
@export var first_checkpoint_spawn_delay_after_unlock: float = 0.25

var _player: CharacterBody3D
var _time_remaining: float = 0.0
var _score: int = 0
var _high_score: int = 0
var _phase: int = GamePhase.LOADING

var _spawn_origin: Vector3 = Vector3.ZERO
var _spawn_ground_origin: Vector3 = Vector3.ZERO
var _spawn_right: Vector3 = Vector3.RIGHT
var _spawn_forward: Vector3 = Vector3.FORWARD
var _spawn_up: Vector3 = Vector3.UP
var _world_origin: Vector3 = Vector3.ZERO
var _world_up: Vector3 = Vector3.UP

var _checkpoint_root: Node3D
var _hud_layer: CanvasLayer
var _hud_time_label: Label
var _hud_score_label: Label
var _hud_best_label: Label
var _hud_status_label: Label
var _compass_root: Control
var _compass_target_marker: ColorRect
var _compass_distance_label: Label
var _game_over_panel: PanelContainer
var _game_over_score: Label
var _pause_panel: PanelContainer
var _upright_sync_frames: int = 0
var _hud_refresh_timer: float = 0.0
var _initial_checkpoint_spawned: bool = false
var _initial_checkpoint_ready_timer: float = 0.0

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
	_phase = GamePhase.LOADING
	_initial_checkpoint_spawned = false
	_initial_checkpoint_ready_timer = 0.0
	_create_hud()
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

func _is_phase(phase: int) -> bool:
	return _phase == phase

func _set_phase(phase: int) -> void:
	_phase = phase

func _process(delta: float) -> void:
	if _is_phase(GamePhase.PLAYING) and Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause_menu()

	if _upright_sync_frames > 0:
		_sync_checkpoint_upright_from_player(true)
		_upright_sync_frames -= 1

	if _is_phase(GamePhase.PAUSED):
		_update_compass()
		_hud_refresh_timer = maxf(_hud_refresh_timer - delta, 0.0)
		if _hud_refresh_timer <= 0.0:
			_update_hud()
			_hud_refresh_timer = maxf(hud_refresh_interval, 0.01)
		return

	if _is_phase(GamePhase.GAME_OVER):
		_update_compass()
		_hud_refresh_timer = maxf(_hud_refresh_timer - delta, 0.0)
		if _hud_refresh_timer <= 0.0:
			_update_hud()
			_hud_refresh_timer = maxf(hud_refresh_interval, 0.01)
		return

	if _is_phase(GamePhase.TRANSITIONING):
		return

	if _player == null:
		if not _is_phase(GamePhase.GAME_OVER):
			_set_phase(GamePhase.LOADING)
		_initial_checkpoint_ready_timer = 0.0
		return
	if not _player.is_physics_processing():
		if not _is_phase(GamePhase.GAME_OVER):
			_set_phase(GamePhase.LOADING)
		_initial_checkpoint_ready_timer = 0.0
		_hud_refresh_timer = maxf(_hud_refresh_timer - delta, 0.0)
		if _hud_refresh_timer <= 0.0:
			_update_hud()
			_hud_refresh_timer = maxf(hud_refresh_interval, 0.01)
		return
	if not _initial_checkpoint_spawned:
		_initial_checkpoint_ready_timer += delta
		if _initial_checkpoint_ready_timer >= maxf(first_checkpoint_spawn_delay_after_unlock, 0.0):
			_spawn_checkpoint()
			_initial_checkpoint_spawned = _checkpoint_root != null
	if _initial_checkpoint_spawned and _is_phase(GamePhase.LOADING):
		_set_phase(GamePhase.PLAYING)

	if not _is_phase(GamePhase.PLAYING):
		_update_compass()
		_hud_refresh_timer = maxf(_hud_refresh_timer - delta, 0.0)
		if _hud_refresh_timer <= 0.0:
			_update_hud()
			_hud_refresh_timer = maxf(hud_refresh_interval, 0.01)
		return

	_time_remaining = maxf(_time_remaining - delta, 0.0)
	if _time_remaining <= 0.0:
		_set_game_over(true)
	_update_compass()
	_hud_refresh_timer = maxf(_hud_refresh_timer - delta, 0.0)
	if _hud_refresh_timer <= 0.0:
		_update_hud()
		_hud_refresh_timer = maxf(hud_refresh_interval, 0.01)

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
		push_warning("Objective HUD scene is missing; ObjectiveSystem UI will be disabled.")
		return

	_hud_time_label = _hud_layer.get_node_or_null("HudPanel/HudInfoContainer/TimeLabel") as Label
	_hud_score_label = _hud_layer.get_node_or_null("HudPanel/HudInfoContainer/ScoreLabel") as Label
	_hud_best_label = _hud_layer.get_node_or_null("HudPanel/HudInfoContainer/BestLabel") as Label
	_hud_status_label = _hud_layer.get_node_or_null("HudPanel/HudInfoContainer/StatusLabel") as Label

	_game_over_panel = _hud_layer.get_node_or_null("GameOverPanel") as PanelContainer
	_game_over_score = _hud_layer.get_node_or_null("GameOverPanel/GameOverMargin/GameOverContainer/ScoreLabel") as Label
	_pause_panel = _hud_layer.get_node_or_null("PausePanel") as PanelContainer
	var restart_button := _hud_layer.get_node_or_null("GameOverPanel/GameOverMargin/GameOverContainer/RestartButton") as Button
	var menu_button := _hud_layer.get_node_or_null("GameOverPanel/GameOverMargin/GameOverContainer/MainMenuButton") as Button
	var resume_button := _hud_layer.get_node_or_null("PausePanel/PauseMargin/PauseContainer/ResumeButton") as Button
	var end_game_button := _hud_layer.get_node_or_null("PausePanel/PauseMargin/PauseContainer/EndGameButton") as Button
	_compass_root = _hud_layer.get_node_or_null("CheckpointCompass") as Control
	_compass_target_marker = _hud_layer.get_node_or_null("CheckpointCompass/CompassBarBg/CompassTargetMarker") as ColorRect
	_compass_distance_label = _hud_layer.get_node_or_null("CheckpointCompass/CompassDistanceLabel") as Label

	if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button and not menu_button.pressed.is_connected(_on_main_menu_pressed):
		menu_button.pressed.connect(_on_main_menu_pressed)
	if resume_button and not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if end_game_button and not end_game_button.pressed.is_connected(_on_end_game_pressed):
		end_game_button.pressed.connect(_on_end_game_pressed)

	if _compass_root:
		_compass_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_compass_root.visible = true

func _update_hud() -> void:
	if _hud_time_label == null or _hud_score_label == null or _hud_best_label == null:
		return

	var time_text := "Time: 0.0" if _is_phase(GamePhase.GAME_OVER) else "Time: %.1f" % _time_remaining
	var score_text := "Score: %d" % _score
	var best_text := "Best: %d" % _high_score
	var status_text := "Objective failed" if _is_phase(GamePhase.GAME_OVER) else ""

	if _hud_time_label.text != time_text:
		_hud_time_label.text = time_text
	if _hud_score_label.text != score_text:
		_hud_score_label.text = score_text
	if _hud_best_label.text != best_text:
		_hud_best_label.text = best_text
	if _hud_status_label and _hud_status_label.text != status_text:
		_hud_status_label.text = status_text

	if _game_over_score:
		if _game_over_score.text != score_text:
			_game_over_score.text = score_text

func _update_compass() -> void:
	if _compass_root == null or _compass_target_marker == null:
		return

	if _player == null or _checkpoint_root == null or _is_phase(GamePhase.GAME_OVER):
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
	if _compass_distance_label:
		_compass_distance_label.text = "%.0fm" % to_checkpoint.length()
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
		_set_paused(false)
	if active:
		_submit_high_score_if_needed()
	_set_phase(GamePhase.GAME_OVER if active else GamePhase.PLAYING)
	_set_player_locked(active)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if active else Input.MOUSE_MODE_CAPTURED
	if _game_over_panel:
		_game_over_panel.visible = active
		if active:
			_game_over_panel.move_to_front()
	if _pause_panel:
		_pause_panel.visible = false

func _toggle_pause_menu() -> void:
	if _is_phase(GamePhase.PLAYING):
		_set_paused(true)
	elif _is_phase(GamePhase.PAUSED):
		_set_paused(false)

func _set_paused(paused: bool) -> void:
	if _is_phase(GamePhase.GAME_OVER) or _is_phase(GamePhase.TRANSITIONING):
		paused = false
	if paused:
		_set_phase(GamePhase.PAUSED)
	elif _is_phase(GamePhase.PAUSED):
		_set_phase(GamePhase.PLAYING)
	_set_player_locked(paused)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	if _pause_panel:
		_pause_panel.visible = paused
		if paused:
			_pause_panel.move_to_front()

func _on_resume_pressed() -> void:
	_set_paused(false)

func _on_end_game_pressed() -> void:
	_set_game_over(true)

func _set_player_locked(locked: bool) -> void:
	if _player == null:
		return
	_player.set_process(not locked)
	_player.set_physics_process(not locked)
	_player.set_process_input(not locked)

func _on_restart_pressed() -> void:
	var tree := get_tree()
	if tree == null or _is_phase(GamePhase.TRANSITIONING):
		return

	var restart_path := world_scene_path
	if tree.current_scene != null and not tree.current_scene.scene_file_path.is_empty():
		restart_path = tree.current_scene.scene_file_path
	if restart_path.is_empty():
		restart_path = "res://node_3d.tscn"

	_begin_scene_transition(restart_path, false, Input.MOUSE_MODE_CAPTURED)

func _on_main_menu_pressed() -> void:
	if get_tree() == null or _is_phase(GamePhase.TRANSITIONING):
		return
	_begin_scene_transition(main_menu_scene_path, false, Input.MOUSE_MODE_VISIBLE)

func _begin_scene_transition(scene_path: String, show_loading_overlay: bool, mouse_mode: Input.MouseMode) -> void:
	if get_tree() == null or scene_path.is_empty():
		return

	_set_phase(GamePhase.TRANSITIONING)
	_set_paused(false)
	_set_player_locked(true)
	Input.mouse_mode = mouse_mode

	var manager := get_node_or_null("/root/SceneTransitionManager")
	if manager != null and manager.has_method("request_transition"):
		var accepted := bool(manager.call("request_transition", scene_path, show_loading_overlay, mouse_mode))
		if accepted:
			return

	push_warning("SceneTransitionManager unavailable or busy; transition cancelled.")
	_set_phase(GamePhase.PLAYING)

func _prepare_cesium_for_scene_exit(tree: SceneTree) -> void:
	if tree.current_scene == null:
		return

	var current := tree.current_scene
	var cameras := current.find_children("*", "AbstractCesiumCamera", true, false)
	for camera_node in cameras:
		if camera_node == null or not is_instance_valid(camera_node):
			continue
		camera_node.set_process(false)

	var tilesets := current.find_children("*", "Cesium3DTileset", true, false)
	for tileset in tilesets:
		if tileset == null or not is_instance_valid(tileset):
			continue
		tileset.set_process(false)
		tileset.set_physics_process(false)

	var georef := current.get_node_or_null("CesiumGeoreference")
	if georef != null and is_instance_valid(georef):
		georef.set_process(false)
		georef.set_physics_process(false)

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

	if _player != null and checkpoint_pos.is_finite():
		var player_ground := _snap_checkpoint_ground_to_surface(_player.global_position)
		var player_anchor := player_ground if player_ground.is_finite() else _player.global_position
		var up := _safe_normalized(_spawn_up, Vector3.UP)
		var to_checkpoint := checkpoint_pos - player_anchor
		var planar_to_checkpoint := to_checkpoint - up * to_checkpoint.dot(up)
		var min_spawn_distance := maxf(checkpoint_min_distance * 0.8, checkpoint_radius * 3.0)
		if planar_to_checkpoint.length() < min_spawn_distance:
			var fallback_dir := _safe_normalized(_spawn_forward, Vector3.FORWARD)
			var moved_planar := _clamp_planar_to_world_border(player_anchor + fallback_dir * min_spawn_distance)
			var moved_ground := _snap_checkpoint_ground_to_surface(moved_planar)
			if moved_ground.is_finite():
				checkpoint_pos = moved_ground
			else:
				var moved := false
				for i in range(8):
					var angle := TAU * (float(i) / 8.0)
					var dir := _spawn_right * cos(angle) + _spawn_forward * sin(angle)
					var ring_planar := _clamp_planar_to_world_border(player_anchor + dir * min_spawn_distance)
					var ring_ground := _snap_checkpoint_ground_to_surface(ring_planar)
					if ring_ground.is_finite():
						checkpoint_pos = ring_ground
						moved = true
						break
				if not moved:
					checkpoint_pos = _clamp_planar_to_world_border(checkpoint_pos)
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
	var max_radius := maxf(world_border_radius - checkpoint_radius - checkpoint_border_margin, 0.0)
	return planar.length() <= max_radius + 0.05

func _clamp_planar_to_world_border(planar_position: Vector3) -> Vector3:
	var up := _safe_normalized(_world_up, Vector3.UP)
	var to_pos := planar_position - _world_origin
	var vertical := up * to_pos.dot(up)
	var planar := to_pos - vertical
	var max_radius := maxf(world_border_radius - checkpoint_radius - checkpoint_border_margin, 0.0)
	var planar_len := planar.length()
	if planar_len <= max_radius:
		return planar_position
	if planar_len < 0.0001:
		return _world_origin + vertical
	return _world_origin + vertical + (planar / planar_len) * max_radius

func _find_checkpoint_ground_position() -> Vector3:
	var base_origin := _spawn_ground_origin if _spawn_ground_origin.is_finite() else _spawn_origin
	var max_radius := maxf(world_border_radius - checkpoint_radius - checkpoint_border_margin, 0.0)
	var effective_spawn_range := minf(checkpoint_spawn_range, max_radius)
	var effective_min_distance := minf(checkpoint_min_distance, effective_spawn_range)
	if effective_spawn_range <= 0.1:
		return base_origin

	for _attempt in range(max_spawn_attempts):
		var distance := randf_range(effective_min_distance, effective_spawn_range)
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
		if planar_distance <= effective_spawn_range + 0.1 and _is_within_world_border(candidate) and planar_distance >= effective_min_distance * 0.7:
			return candidate

	var fallback_planar := base_origin + _spawn_forward * effective_min_distance
	fallback_planar = _clamp_planar_to_world_border(fallback_planar)
	var fallback_ground := _snap_checkpoint_ground_to_surface(fallback_planar)
	if fallback_ground.is_finite():
		return fallback_ground

	var safe_distance := maxf(checkpoint_radius * 3.0, effective_min_distance * 0.8)
	if safe_distance > 0.1:
		for i in range(12):
			var angle := TAU * (float(i) / 12.0)
			var planar_dir := _spawn_right * cos(angle) + _spawn_forward * sin(angle)
			var ring_planar := _clamp_planar_to_world_border(base_origin + planar_dir * safe_distance)
			var ring_ground := _snap_checkpoint_ground_to_surface(ring_planar)
			if ring_ground.is_finite() and _is_within_world_border(ring_ground):
				return ring_ground

	if _spawn_ground_origin.is_finite():
		return _spawn_ground_origin

	return Vector3(INF, INF, INF)

func _on_checkpoint_body_entered(body: Node) -> void:
	if not _is_phase(GamePhase.PLAYING):
		return
	if body != _player:
		return
	if not _initial_checkpoint_spawned:
		return
	if not _player.is_physics_processing():
		return

	_score += checkpoint_points
	_submit_high_score_if_needed()
	_time_remaining += checkpoint_time_bonus_seconds
	_spawn_checkpoint()
	_update_hud()
