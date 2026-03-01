extends CharacterBody3D

## First-person character controller for use with Cesium 3D Tiles

@export var move_speed: float = 5.0
@export var sprint_speed: float = 10.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.005
@export var ground_acceleration: float = 55.0
@export var ground_deceleration: float = 70.0
@export var air_acceleration: float = 16.0
@export var air_deceleration: float = 8.0
@export var air_control_multiplier: float = 0.85
@export var parkour_turn_assist: float = 26.0
@export var parkour_turn_assist_dot_threshold: float = 0.2
@export var sprint_jump_forward_boost: float = 2.8
@export var bunnyhop_grace_time: float = 0.22
@export var bunnyhop_speed_bonus: float = 1.6
@export var bunnyhop_max_speed: float = 22.0
@export var slope_boost_strength: float = 18.0
@export var slope_boost_max_angle_degrees: float = 45.0
@export var world_border_enabled: bool = true
@export var world_border_radius: float = 200.0
@export var world_border_height: float = 420.0
@export var world_border_visible_distance: float = 40.0
@export var world_border_ground_embed_depth: float = 160.0
@export var world_border_ground_probe_height: float = 400.0
@export_flags_3d_physics var world_border_ground_collision_mask: int = 1
@export var world_border_base_alpha: float = 0.28
@export var world_border_color: Color = Color(0.25, 0.9, 1.0, 1.0)
@export var world_border_visible_arc_degrees: float = 70.0
@export var world_border_arc_fade_degrees: float = 20.0
@export var air_strafe_enabled: bool = true
@export var air_strafe_bonus_acceleration: float = 20.0
@export var air_strafe_min_speed: float = 6.0
@export var air_strafe_max_bonus_speed: float = 24.0
@export var air_strafe_input_dot_max: float = 0.75
@export var coyote_time: float = 0.14
@export var jump_buffer_time: float = 0.12
@export var fall_gravity_multiplier: float = 1.6
@export var low_jump_gravity_multiplier: float = 2.2
@export var max_fall_speed: float = 45.0
@export var stop_speed_threshold: float = 0.35
@export var sprint_fov_boost: float = 6.0
@export var sprint_fov_lerp_speed: float = 8.0
@export var camera_bank_enabled: bool = true
@export var camera_bank_max_degrees: float = 6.0
@export var camera_bank_speed: float = 10.0
@export var camera_bank_grapple_multiplier: float = 1.25
@export var wall_jump_enabled: bool = true
@export var wall_jump_coyote_time: float = 0.18
@export var wall_jump_cooldown: float = 0.2
@export var wall_jump_push_speed: float = 7.5
@export var wall_jump_forward_boost: float = 2.5
@export var wall_jump_vertical_speed: float = 5.2
@export var wall_max_up_dot: float = 0.35
@export var grapple_enabled: bool = true
@export var grapple_max_distance: float = 80.0
@export var grapple_min_hit_distance: float = 1.5
@export var grapple_ray_max_scan_hits: int = 12
@export var grapple_pull_strength: float = 85.0
@export var grapple_gravity_scale: float = 0.7
@export var grapple_radial_damping: float = 0.02
@export var grapple_collision_mask: int = 1
@export var grapple_use_aim_assist: bool = false
@export var grapple_aim_assist_radius_pixels: float = 28.0
@export var grapple_aim_assist_rings: int = 2
@export var grapple_aim_assist_samples_per_ring: int = 8
@export var grapple_min_rope_length: float = 2.0
@export var grapple_reel_speed: float = 32.0
@export var grapple_swing_acceleration: float = 46.0
@export var grapple_detach_boost: float = 1.35
@export var grapple_detach_up_boost: float = 0.4
@export var grapple_rehook_cooldown: float = 0.08
@export var grapple_latch_impulse: float = 11.0
@export var grapple_anchor_acceleration: float = 65.0
@export var grapple_max_speed: float = 42.0
@export var grapple_auto_release_distance: float = 2.4
@export var grapple_downward_pull_bonus: float = 0.7
@export var grapple_downward_gravity_assist: float = 22.0
@export var grapple_detach_directional_boost: float = 0.9
@export var grapple_downward_full_gravity_threshold: float = 0.25
@export var grapple_cooldown_seconds: float = 10.0
@export var grapple_rope_visual_enabled: bool = true
@export var grapple_rope_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export var grapple_rope_radius: float = 0.01
@export var landing_impact_min_speed: float = 8.0
@export var landing_impact_fov_kick: float = 3.0
@export var grapple_latch_fov_kick: float = 1.8
@export var impact_fov_return_speed: float = 11.0
@export var impact_fov_max_offset: float = 8.0
@export var grapple_crosshair_enabled: bool = true
@export var grapple_crosshair_size: float = 12.0
@export var grapple_crosshair_thickness: float = 2.0
@export var grapple_crosshair_gap: float = 4.0
@export var grapple_crosshair_color_valid: Color = Color(0.22, 0.95, 1.0, 0.95)
@export var grapple_crosshair_color_invalid: Color = Color(1.0, 0.35, 0.35, 0.85)
@export var grapple_crosshair_color_latched: Color = Color(1.0, 0.9, 0.32, 0.95)
@export var grapple_crosshair_probe_interval: float = 0.06
@export var show_debug_text: bool = true
@export var debug_font_size: int = 14

var gravity: float = 9.8
var yaw: float = 0.0
var pitch: float = 0.0
var surface_basis: Basis = Basis.IDENTITY
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var wall_jump_timer: float = 0.0
var wall_jump_cooldown_timer: float = 0.0
var wall_jump_normal: Vector3 = Vector3.ZERO
var base_camera_fov: float = 75.0
var last_has_input: bool = false
var last_is_sprinting: bool = false
var debug_layer: CanvasLayer
var debug_label: Label
var debug_horizontal_speed: float = 0.0
var debug_vertical_speed: float = 0.0
var debug_is_grounded: bool = false
var debug_can_jump: bool = false
var debug_can_wall_jump: bool = false
var grapple_active: bool = false
var grapple_point: Vector3 = Vector3.ZERO
var grapple_rope_length: float = 0.0
var grapple_button_was_down: bool = false
var grapple_rehook_timer: float = 0.0
var grapple_cooldown_timer: float = 0.0
var grapple_reel_dir: float = 0.0
var grapple_rope_mesh_instance: MeshInstance3D
var grapple_rope_mesh: CylinderMesh
var grapple_rope_material: StandardMaterial3D
var impact_fov_offset: float = 0.0
var was_grounded_last_frame: bool = false
var camera_base_roll: float = 0.0
var camera_bank_roll: float = 0.0
var bunnyhop_grace_timer: float = 0.0
var world_border_origin: Vector3 = Vector3.ZERO
var world_border_up: Vector3 = Vector3.UP
var world_border_mesh_instance: MeshInstance3D
var world_border_material: ShaderMaterial
var _border_upright_sync_frames: int = 0
var grapple_crosshair_layer: CanvasLayer
var grapple_crosshair_center: Control
var grapple_crosshair_h: ColorRect
var grapple_crosshair_v: ColorRect
var grapple_indicator_root: Control
var grapple_indicator_icon: Label
var grapple_indicator_bar_fill: ColorRect
var _grapple_crosshair_probe_timer: float = 0.0
var _grapple_crosshair_cached_can_grapple: bool = false
var _grapple_crosshair_cached_valid: bool = false

func _add_impact_fov(amount: float) -> void:
	impact_fov_offset = clampf(impact_fov_offset + amount, -impact_fov_max_offset, impact_fov_max_offset)

func _setup_world_border_visual() -> void:
	var result := PlayerBorderModule.setup_world_border_visual(self, world_border_enabled, world_border_radius, world_border_height, world_border_color, world_border_base_alpha, world_border_visible_arc_degrees, world_border_arc_fade_degrees)
	if result.is_empty():
		return
	world_border_mesh_instance = result.get("mesh_instance", null)
	world_border_material = result.get("material", null)

func _snap_position_to_ground_along_up(sample_position: Vector3, up: Vector3) -> Vector3:
	return PlayerBorderModule.snap_position_to_ground_along_up(self, sample_position, up, world_border_ground_probe_height, world_border_height, world_border_ground_collision_mask, self)

func _update_world_border_visual() -> void:
	PlayerBorderModule.update_world_border_visual(world_border_mesh_instance, world_border_material, world_border_enabled, world_border_up, world_border_origin, world_border_height, world_border_ground_embed_depth, world_border_radius, world_border_visible_distance, world_border_base_alpha, world_border_color, world_border_visible_arc_degrees, world_border_arc_fade_degrees, global_position)

func _enforce_world_border() -> void:
	var result := PlayerBorderModule.enforce_world_border(world_border_enabled, world_border_up, world_border_origin, world_border_radius, global_position, velocity)
	global_position = result.get("position", global_position)
	velocity = result.get("velocity", velocity)

func _sync_world_border_upright_from_player(adjust_origin: bool) -> void:
	if not world_border_enabled:
		return
	world_border_up = _safe_normalized(up_direction, _safe_normalized(surface_basis.y, world_border_up))
	if adjust_origin:
		world_border_origin = _snap_position_to_ground_along_up(world_border_origin, world_border_up)
	_update_world_border_visual()

func _apply_air_strafe_bonus(horizontal_velocity: Vector3, move_direction: Vector3, up_dir: Vector3, delta: float) -> Vector3:
	return PlayerMovementModule.apply_air_strafe_bonus(horizontal_velocity, move_direction, up_dir, delta, air_strafe_enabled, air_strafe_min_speed, air_strafe_input_dot_max, air_strafe_bonus_acceleration, air_strafe_max_bonus_speed, global_basis, surface_basis)

func _setup_grapple_visual() -> void:
	if not grapple_rope_visual_enabled:
		return
	grapple_rope_mesh_instance = MeshInstance3D.new()
	grapple_rope_mesh_instance.name = "GrappleRope"
	grapple_rope_mesh = CylinderMesh.new()
	grapple_rope_mesh.top_radius = grapple_rope_radius
	grapple_rope_mesh.bottom_radius = grapple_rope_radius
	grapple_rope_mesh.radial_segments = 12
	grapple_rope_mesh.height = 0.1
	grapple_rope_material = StandardMaterial3D.new()
	grapple_rope_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grapple_rope_material.albedo_color = grapple_rope_color
	grapple_rope_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	grapple_rope_material.disable_receive_shadows = true
	grapple_rope_mesh_instance.mesh = grapple_rope_mesh
	grapple_rope_mesh_instance.material_override = grapple_rope_material
	grapple_rope_mesh_instance.top_level = true
	grapple_rope_mesh_instance.visible = false
	add_child(grapple_rope_mesh_instance)

func _update_grapple_visual() -> void:
	if not grapple_rope_visual_enabled or grapple_rope_mesh_instance == null or grapple_rope_mesh == null:
		return

	if not grapple_active or camera == null or not camera.is_inside_tree() or not grapple_point.is_finite():
		grapple_rope_mesh_instance.visible = false
		return

	var start_pos := camera.global_position
	var end_pos := grapple_point
	var rope_vec := end_pos - start_pos
	var rope_len := rope_vec.length()
	if rope_len < 0.05:
		grapple_rope_mesh_instance.visible = false
		return

	var rope_dir := rope_vec / rope_len
	var up_ref := Vector3.UP
	if absf(rope_dir.dot(up_ref)) > 0.99:
		up_ref = Vector3.RIGHT
	var right := up_ref.cross(rope_dir).normalized()
	var forward := rope_dir.cross(right).normalized()
	var rope_basis := Basis(right, rope_dir, forward)
	var rope_mid := start_pos + rope_vec * 0.5

	grapple_rope_mesh.height = rope_len
	grapple_rope_mesh.top_radius = grapple_rope_radius
	grapple_rope_mesh.bottom_radius = grapple_rope_radius
	grapple_rope_mesh_instance.global_transform = Transform3D(rope_basis, rope_mid)
	grapple_rope_mesh_instance.visible = true

func _safe_normalized(v: Vector3, fallback: Vector3) -> Vector3:
	if not v.is_finite() or v.length_squared() < 0.000001:
		return fallback
	return v.normalized()

@onready var camera: Camera3D = $CesiumStaticCamera
@onready var globe_node: CesiumGeoreference = null

func _setup_debug_ui() -> void:
	var result := PlayerUiModule.bind_debug_ui(self, show_debug_text, debug_font_size)
	debug_layer = result.get("debug_layer", null)
	debug_label = result.get("debug_label", null)

func _setup_grapple_crosshair_ui() -> void:
	if not grapple_crosshair_enabled:
		return
	var result := PlayerUiModule.bind_grapple_crosshair_ui(self, grapple_crosshair_size, grapple_crosshair_thickness, grapple_crosshair_gap, grapple_crosshair_color_invalid, grapple_crosshair_color_valid)
	grapple_crosshair_layer = result.get("grapple_crosshair_layer", null)
	grapple_crosshair_center = result.get("grapple_crosshair_center", null)
	grapple_crosshair_h = result.get("grapple_crosshair_h", null)
	grapple_crosshair_v = result.get("grapple_crosshair_v", null)
	grapple_indicator_root = result.get("grapple_indicator_root", null)
	grapple_indicator_icon = result.get("grapple_indicator_icon", null)
	grapple_indicator_bar_fill = result.get("grapple_indicator_bar_fill", null)

func _set_grapple_indicator(color: Color, fill_ratio: float) -> void:
	PlayerUiModule.set_grapple_indicator(grapple_indicator_icon, grapple_indicator_bar_fill, color, fill_ratio)

func _set_crosshair_color(color: Color) -> void:
	PlayerUiModule.set_crosshair_color(grapple_crosshair_h, grapple_crosshair_v, color)

func _get_center_ray_direction() -> Vector3:
	if camera == null or not camera.is_inside_tree():
		return Vector3.ZERO
	var viewport := get_viewport()
	if viewport == null:
		return -camera.global_basis.z
	var viewport_center := viewport.get_visible_rect().size * 0.5
	var dir := camera.project_ray_normal(viewport_center)
	if not dir.is_finite() or dir.length_squared() < 0.000001:
		return -camera.global_basis.z
	return dir.normalized()

func _update_grapple_crosshair(delta: float) -> void:
	if not grapple_crosshair_enabled or grapple_crosshair_layer == null:
		return

	var should_show := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and camera != null and camera.is_inside_tree() and grapple_enabled
	grapple_crosshair_layer.visible = should_show
	if not should_show:
		_grapple_crosshair_cached_valid = false
		return
	if grapple_active:
		_set_crosshair_color(grapple_crosshair_color_latched)
		_set_grapple_indicator(grapple_crosshair_color_latched, 1.0)
		return

	if grapple_cooldown_timer > 0.0:
		_set_crosshair_color(grapple_crosshair_color_invalid)
		var cooldown_total := maxf(grapple_cooldown_seconds, 0.001)
		var fill_ratio := clampf(1.0 - (grapple_cooldown_timer / cooldown_total), 0.0, 1.0)
		_set_grapple_indicator(grapple_crosshair_color_invalid, fill_ratio)
		_grapple_crosshair_cached_valid = false
		return

	_grapple_crosshair_probe_timer -= delta
	if _grapple_crosshair_probe_timer <= 0.0 or not _grapple_crosshair_cached_valid:
		var origin := camera.global_position
		var center_dir := _get_center_ray_direction()
		var hit := _cast_grapple_ray(origin, center_dir)
		_grapple_crosshair_cached_can_grapple = not hit.is_empty()
		_grapple_crosshair_cached_valid = true
		_grapple_crosshair_probe_timer = maxf(grapple_crosshair_probe_interval, 0.01)

	var can_grapple := _grapple_crosshair_cached_can_grapple
	_set_crosshair_color(grapple_crosshair_color_valid if can_grapple else grapple_crosshair_color_invalid)
	_set_grapple_indicator(grapple_crosshair_color_valid if can_grapple else grapple_crosshair_color_invalid, 1.0)

func _update_debug_text() -> void:
	if debug_label == null:
		return
	if not show_debug_text:
		debug_label.text = ""
		return

	debug_label.text = "Speed: %.2f\nSprinting: %s\nGrounded: %s\nCan Jump: %s\nCan Wall Jump: %s\nGrapple: %s\nRope Len: %.1f\nCoyote: %.2f\nJump Buffer: %.2f\nWall Jump Timer: %.2f" % [
		debug_horizontal_speed,
		str(last_is_sprinting and last_has_input),
		str(debug_is_grounded),
		str(debug_can_jump),
		str(debug_can_wall_jump),
		str(grapple_active),
		grapple_rope_length,
		coyote_timer,
		jump_buffer_timer,
		wall_jump_timer
	]

func _stop_grapple(add_detach_boost: bool = false, up_dir: Vector3 = Vector3.UP, rope_dir: Vector3 = Vector3.ZERO) -> void:
	if add_detach_boost and grapple_active and velocity.is_finite():
		velocity *= grapple_detach_boost
		var safe_up := _safe_normalized(up_dir, Vector3.UP)
		var safe_rope := _safe_normalized(rope_dir, Vector3.ZERO)
		if safe_rope != Vector3.ZERO:
			var downward_factor := clampf(-safe_rope.dot(safe_up), 0.0, 1.0)
			if downward_factor > 0.12:
				velocity += safe_rope * (grapple_detach_directional_boost * downward_factor)
			else:
				velocity += safe_up * grapple_detach_up_boost
		else:
			velocity += safe_up * grapple_detach_up_boost
	grapple_rehook_timer = grapple_rehook_cooldown
	grapple_active = false
	grapple_point = Vector3.ZERO
	grapple_rope_length = 0.0
	grapple_reel_dir = 0.0
	if grapple_rope_mesh_instance:
		grapple_rope_mesh_instance.visible = false

func _cast_grapple_ray(origin: Vector3, direction: Vector3) -> Dictionary:
	return PlayerGrappleModule.cast_grapple_ray(self, self, origin, direction, grapple_max_distance, grapple_min_hit_distance, grapple_collision_mask)

func _find_best_grapple_hit() -> Dictionary:
	if camera == null or not camera.is_inside_tree():
		return {}

	var origin := camera.global_position
	var center_dir := _get_center_ray_direction()
	return _cast_grapple_ray(origin, center_dir)

func _try_start_grapple() -> void:
	if not grapple_enabled or camera == null or not camera.is_inside_tree() or grapple_rehook_timer > 0.0 or grapple_cooldown_timer > 0.0:
		return

	var hit := _find_best_grapple_hit()
	if hit.is_empty():
		return

	var hit_pos: Vector3 = hit.position
	if not hit_pos.is_finite():
		return

	grapple_point = hit_pos
	grapple_rope_length = global_position.distance_to(grapple_point)
	if grapple_rope_length < 0.05:
		return
	grapple_active = true
	grapple_cooldown_timer = maxf(grapple_cooldown_seconds, 0.0)
	grapple_reel_dir = 0.0
	var latch_dir := _safe_normalized(grapple_point - global_position, Vector3.ZERO)
	if latch_dir != Vector3.ZERO:
		velocity += latch_dir * grapple_latch_impulse
		_add_impact_fov(grapple_latch_fov_kick)

func _apply_grapple_physics(delta: float, move_direction: Vector3, up_dir: Vector3) -> void:
	if not grapple_active:
		return

	var to_anchor := grapple_point - global_position
	if not to_anchor.is_finite() or to_anchor.length_squared() < 0.0001:
		_stop_grapple()
		return

	var distance_to_anchor := to_anchor.length()
	var rope_dir := to_anchor / distance_to_anchor
	if distance_to_anchor <= grapple_auto_release_distance:
		_stop_grapple(true, up_dir, rope_dir)
		return
	grapple_rope_length = clampf(grapple_rope_length - grapple_reel_dir * grapple_reel_speed * delta, 0.05, grapple_max_distance)
	var safe_up := _safe_normalized(up_dir, surface_basis.y)
	var downward_factor := clampf(-rope_dir.dot(safe_up), 0.0, 1.0)
	var anchor_accel := grapple_anchor_acceleration * (1.0 + downward_factor * grapple_downward_pull_bonus)
	velocity += rope_dir * (anchor_accel * delta)
	if downward_factor > 0.0:
		velocity -= safe_up * (grapple_downward_gravity_assist * downward_factor * delta)

	if distance_to_anchor > grapple_rope_length:
		var stretch := distance_to_anchor - grapple_rope_length
		velocity += rope_dir * (stretch * grapple_pull_strength * delta)

	var radial_speed := velocity.dot(rope_dir)
	if distance_to_anchor >= grapple_rope_length and radial_speed < 0.0:
		velocity -= rope_dir * (radial_speed * (1.0 - grapple_radial_damping))

	var max_radial_out_speed := 0.0
	var radial_speed_now := velocity.dot(rope_dir)
	if distance_to_anchor >= grapple_rope_length and radial_speed_now < max_radial_out_speed:
		velocity -= rope_dir * (radial_speed_now - max_radial_out_speed)

	if move_direction != Vector3.ZERO:
		var tangent_input := move_direction - rope_dir * move_direction.dot(rope_dir)
		if tangent_input.length_squared() > 0.000001:
			velocity += tangent_input.normalized() * grapple_swing_acceleration * delta

	var speed := velocity.length()
	if speed > grapple_max_speed:
		velocity = velocity / speed * grapple_max_speed

func sync_globe_ecef_from_delta(delta_engine: Vector3) -> void:
	if globe_node == null or not globe_node.is_inside_tree() or camera == null or not camera.is_inside_tree():
		return
	
	if globe_node.origin_type != CesiumGeoreference.OriginType.CartographicOrigin:
		return

	if delta_engine.length_squared() < 0.0000001:
		return

	var tx_engine_to_ecef: Transform3D = globe_node.get_initial_tx_engine_to_ecef()
	var delta_ecef := tx_engine_to_ecef.basis * delta_engine

	globe_node.ecefX += delta_ecef.x
	globe_node.ecefY += delta_ecef.y
	globe_node.ecefZ += delta_ecef.z

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Get globe node reference from camera
	if camera and camera.globe_node:
		globe_node = camera.globe_node
	surface_basis = calculate_surface_basis()
	if surface_basis.y.is_finite() and surface_basis.y.length_squared() > 0.000001:
		up_direction = surface_basis.y.normalized()
		update_orientation()
	if camera:
		base_camera_fov = camera.fov
		camera_base_roll = camera.rotation.z
	was_grounded_last_frame = is_on_floor()
	world_border_up = _safe_normalized(surface_basis.y, up_direction)
	world_border_origin = _snap_position_to_ground_along_up(global_position, world_border_up)
	_setup_world_border_visual()
	_border_upright_sync_frames = 8
	_setup_grapple_visual()
	_setup_debug_ui()
	_setup_grapple_crosshair_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Accumulate yaw and pitch (positive values for natural mouse movement)
		yaw += event.relative.x * mouse_sensitivity
		pitch += event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -PI/2, PI/2)
	
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("jump"):
		jump_buffer_timer = jump_buffer_time

	if event.is_action_pressed("toggle_debug"):
		show_debug_text = not show_debug_text
		if debug_layer:
			debug_layer.visible = show_debug_text

func calculate_surface_basis() -> Basis:
	return PlayerMovementModule.calculate_surface_basis(globe_node, surface_basis, global_basis, global_position)

func update_orientation() -> void:
	surface_basis = calculate_surface_basis()
	if not surface_basis.x.is_finite() or not surface_basis.y.is_finite() or not surface_basis.z.is_finite():
		return
	
	# Apply yaw rotation around the up axis (Y) - use negative yaw like CesiumDynamicCamera
	var oriented_basis: Basis = surface_basis.rotated(surface_basis.y.normalized(), -yaw)
	
	# Apply pitch rotation around X axis (after yaw rotation)
	oriented_basis = oriented_basis.rotated(oriented_basis.x, pitch)
	
	# Flip X axis like CesiumDynamicCamera does
	oriented_basis.x = -oriented_basis.x
	
	# Set the character's basis to the oriented surface basis
	if not oriented_basis.x.is_finite() or not oriented_basis.y.is_finite() or not oriented_basis.z.is_finite():
		return
	global_basis = oriented_basis
	
	# Reset yaw to prevent accumulation/momentum
	yaw = 0.0

func _process(delta: float) -> void:
	# Update orientation every frame to stay aligned with surface
	update_orientation()
	if _border_upright_sync_frames > 0:
		_sync_world_border_upright_from_player(true)
		_border_upright_sync_frames -= 1

	if camera and camera.is_inside_tree():
		impact_fov_offset = move_toward(impact_fov_offset, 0.0, impact_fov_return_speed * delta)
		var up_dir := _safe_normalized(surface_basis.y, Vector3.UP)
		var right_dir := _safe_normalized(global_basis.x - up_dir * global_basis.x.dot(up_dir), surface_basis.x)
		var horizontal_velocity := velocity - up_dir * velocity.dot(up_dir)
		var lateral_speed := horizontal_velocity.dot(right_dir)
		var bank_target := 0.0
		if camera_bank_enabled:
			var speed_ref := maxf(sprint_speed, 0.001)
			var lateral_ratio := clampf(lateral_speed / speed_ref, -1.0, 1.0)
			var grapple_mult := camera_bank_grapple_multiplier if grapple_active else 1.0
			bank_target = deg_to_rad(camera_bank_max_degrees) * lateral_ratio * grapple_mult
		camera_bank_roll = move_toward(camera_bank_roll, bank_target, camera_bank_speed * delta)
		camera.rotation.z = camera_base_roll + camera_bank_roll

		var target_fov := base_camera_fov
		if last_is_sprinting and last_has_input:
			target_fov += sprint_fov_boost
		target_fov += impact_fov_offset
		camera.fov = move_toward(camera.fov, target_fov, sprint_fov_lerp_speed * delta)

	_update_grapple_visual()
	_update_world_border_visual()
	_update_grapple_crosshair(delta)

	_update_debug_text()

func _physics_process(delta: float) -> void:
	grapple_rehook_timer = maxf(grapple_rehook_timer - delta, 0.0)
	grapple_cooldown_timer = maxf(grapple_cooldown_timer - delta, 0.0)
	grapple_reel_dir = move_toward(grapple_reel_dir, 0.0, delta * 4.0)

	if grapple_enabled:
		var grapple_button_down := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		if grapple_button_down and not grapple_button_was_down:
			_try_start_grapple()
		elif not grapple_button_down and grapple_button_was_down:
			var detach_rope_dir := _safe_normalized(grapple_point - global_position, Vector3.ZERO)
			_stop_grapple(true, surface_basis.y, detach_rope_dir)
		grapple_button_was_down = grapple_button_down

	# Get the surface up direction (local Y in surface_basis)
	var up_dir: Vector3 = surface_basis.y
	
	# Set up_direction for CharacterBody3D to align with surface
	up_direction = up_dir

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_time
	jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)
	bunnyhop_grace_timer = maxf(bunnyhop_grace_timer - delta, 0.0)
	wall_jump_timer = maxf(wall_jump_timer - delta, 0.0)
	wall_jump_cooldown_timer = maxf(wall_jump_cooldown_timer - delta, 0.0)

	var is_grounded := is_on_floor()
	if is_grounded:
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)
	
	# Get input direction
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var has_input := input_dir.length_squared() > 0.000001
	
	# Apply sprint
	var is_sprinting := Input.is_action_pressed("sprint")
	var current_speed := sprint_speed if is_sprinting else move_speed
	last_is_sprinting = is_sprinting
	last_has_input = has_input
	
	# Calculate movement direction in the character's local space (on the surface plane)
	# Project movement onto the surface plane to prevent moving into/away from the ground
	var forward := global_basis.z
	var right := global_basis.x
	
	# Remove any component pointing into/away from surface
	forward = _safe_normalized(forward - up_dir * forward.dot(up_dir), -surface_basis.z)
	right = _safe_normalized(right - up_dir * right.dot(up_dir), surface_basis.x)
	
	# Calculate desired movement direction
	var move_direction := _safe_normalized((right * input_dir.x + forward * input_dir.y), Vector3.ZERO)
	
	var vertical_speed := velocity.dot(up_dir)
	var horizontal_velocity := velocity - up_dir * vertical_speed
	var target_horizontal_velocity := move_direction * current_speed

	if not is_grounded:
		target_horizontal_velocity *= air_control_multiplier

	var accel_rate := ground_acceleration if is_grounded else air_acceleration
	var decel_rate := ground_deceleration if is_grounded else air_deceleration
	if has_input:
		horizontal_velocity = horizontal_velocity.move_toward(target_horizontal_velocity, accel_rate * delta)
	else:
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, decel_rate * delta)
		if is_grounded and horizontal_velocity.length() < stop_speed_threshold:
			horizontal_velocity = Vector3.ZERO

	if is_grounded and has_input and horizontal_velocity.length_squared() > 0.25:
		var current_dir := horizontal_velocity.normalized()
		var dir_dot := current_dir.dot(move_direction)
		if dir_dot < parkour_turn_assist_dot_threshold:
			horizontal_velocity = horizontal_velocity.move_toward(target_horizontal_velocity, parkour_turn_assist * delta)

	if is_grounded and has_input and slope_boost_strength > 0.0 and is_on_floor():
		var floor_n := _safe_normalized(get_floor_normal(), up_dir)
		var steepness := clampf(1.0 - floor_n.dot(up_dir), 0.0, 1.0)
		var slope_angle_ok := floor_n.dot(up_dir) >= cos(deg_to_rad(slope_boost_max_angle_degrees))
		if steepness > 0.0001 and slope_angle_ok:
			var downhill := -up_dir - floor_n * (-up_dir).dot(floor_n)
			downhill = _safe_normalized(downhill, Vector3.ZERO)
			if downhill != Vector3.ZERO:
				var downhill_dot := clampf(move_direction.dot(downhill), 0.0, 1.0)
				if downhill_dot > 0.0:
					horizontal_velocity += downhill * (slope_boost_strength * steepness * downhill_dot * delta)

	if not is_grounded and has_input:
		horizontal_velocity = _apply_air_strafe_bonus(horizontal_velocity, move_direction, up_dir, delta)

	var can_jump := is_grounded or coyote_timer > 0.0
	if jump_buffer_timer > 0.0 and can_jump:
		var jump_move_boost := move_direction * sprint_jump_forward_boost
		if not last_is_sprinting:
			jump_move_boost *= 0.6
		horizontal_velocity += jump_move_boost

		if bunnyhop_grace_timer > 0.0 and has_input:
			var pre_speed := horizontal_velocity.length()
			if pre_speed > 0.0:
				var boosted_speed := minf(pre_speed + bunnyhop_speed_bonus, bunnyhop_max_speed)
				horizontal_velocity = horizontal_velocity / pre_speed * boosted_speed
			bunnyhop_grace_timer = 0.0

		vertical_speed = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		is_grounded = false

	if wall_jump_enabled and jump_buffer_timer > 0.0 and not can_jump and wall_jump_timer > 0.0 and wall_jump_cooldown_timer <= 0.0:
		var jump_normal := _safe_normalized(wall_jump_normal, Vector3.ZERO)
		if jump_normal != Vector3.ZERO:
			horizontal_velocity *= 0.35
			horizontal_velocity += jump_normal * wall_jump_push_speed
			if has_input:
				horizontal_velocity += move_direction * wall_jump_forward_boost
			vertical_speed = maxf(vertical_speed, wall_jump_vertical_speed)
			jump_buffer_timer = 0.0
			wall_jump_timer = 0.0
			wall_jump_cooldown_timer = wall_jump_cooldown

	if not is_grounded:
		var gravity_multiplier := 1.0
		if vertical_speed < 0.0:
			gravity_multiplier = fall_gravity_multiplier
		elif vertical_speed > 0.0 and not Input.is_action_pressed("jump"):
			gravity_multiplier = low_jump_gravity_multiplier
		if grapple_active:
			var grapple_dir := _safe_normalized(grapple_point - global_position, Vector3.ZERO)
			var grapple_downward_factor := 0.0
			if grapple_dir != Vector3.ZERO:
				grapple_downward_factor = clampf(-grapple_dir.dot(up_dir), 0.0, 1.0)
			if grapple_downward_factor >= grapple_downward_full_gravity_threshold:
				gravity_multiplier = maxf(gravity_multiplier, 1.0)
			else:
				gravity_multiplier *= grapple_gravity_scale

		vertical_speed -= gravity * gravity_multiplier * delta
		vertical_speed = maxf(vertical_speed, -max_fall_speed)

	# Combine horizontal and vertical velocities
	velocity = horizontal_velocity + up_dir * vertical_speed
	_apply_grapple_physics(delta, move_direction, up_dir)
	debug_horizontal_speed = horizontal_velocity.length()
	debug_vertical_speed = vertical_speed
	debug_is_grounded = is_grounded
	debug_can_jump = can_jump
	debug_can_wall_jump = wall_jump_enabled and wall_jump_timer > 0.0 and wall_jump_cooldown_timer <= 0.0 and not is_grounded
	if not velocity.is_finite():
		velocity = Vector3.ZERO
	
	var prev_camera_pos := Vector3.ZERO
	var has_prev_camera_pos := false
	if camera and camera.is_inside_tree() and camera.global_position.is_finite():
		prev_camera_pos = camera.global_position
		has_prev_camera_pos = true

	var pre_move_vertical_speed := velocity.dot(up_dir)
	move_and_slide()
	if not global_position.is_finite():
		global_position = Vector3.ZERO
		velocity = Vector3.ZERO
	_enforce_world_border()

	var grounded_now := is_on_floor()
	if grounded_now and not was_grounded_last_frame and pre_move_vertical_speed < -landing_impact_min_speed:
		var impact_strength := clampf((absf(pre_move_vertical_speed) - landing_impact_min_speed) / maxf(landing_impact_min_speed, 0.001), 0.0, 1.5)
		_add_impact_fov(landing_impact_fov_kick * impact_strength)
	if grounded_now and not was_grounded_last_frame:
		bunnyhop_grace_timer = bunnyhop_grace_time
	was_grounded_last_frame = grounded_now

	if grounded_now:
		wall_jump_timer = 0.0
		wall_jump_normal = Vector3.ZERO
	elif wall_jump_enabled:
		var best_wall_normal := Vector3.ZERO
		for collision_index in range(get_slide_collision_count()):
			var collision := get_slide_collision(collision_index)
			if collision == null:
				continue
			var normal: Vector3 = collision.get_normal()
			if not normal.is_finite():
				continue
			if absf(normal.dot(up_dir)) <= wall_max_up_dot:
				best_wall_normal = normal
				break

		if best_wall_normal != Vector3.ZERO:
			wall_jump_normal = best_wall_normal
			wall_jump_timer = wall_jump_coyote_time

	var delta_engine := Vector3.ZERO
	if has_prev_camera_pos and camera and camera.is_inside_tree() and camera.global_position.is_finite():
		delta_engine = camera.global_position - prev_camera_pos

	if delta_engine.length_squared() < 0.0000001 and has_input:
		delta_engine = move_direction * current_speed * delta

	sync_globe_ecef_from_delta(delta_engine)
