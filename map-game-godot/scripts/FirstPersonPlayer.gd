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
var grapple_indicator_bar_bg: ColorRect
var grapple_indicator_bar_fill: ColorRect

func _add_impact_fov(amount: float) -> void:
	impact_fov_offset = clampf(impact_fov_offset + amount, -impact_fov_max_offset, impact_fov_max_offset)

func _setup_world_border_visual() -> void:
	if not world_border_enabled:
		return

	world_border_mesh_instance = MeshInstance3D.new()
	world_border_mesh_instance.name = "WorldBorder"
	world_border_mesh_instance.top_level = true
	world_border_mesh_instance.visible = false

	var mesh := CylinderMesh.new()
	mesh.top_radius = world_border_radius
	mesh.bottom_radius = world_border_radius
	mesh.height = world_border_height
	mesh.radial_segments = 96
	world_border_mesh_instance.mesh = mesh

	var border_shader := Shader.new()
	border_shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled, blend_mix;\n\nuniform vec4 border_color : source_color = vec4(0.25, 0.9, 1.0, 1.0);\nuniform float global_alpha = 0.3;\nuniform float section_center_u = 0.0;\nuniform float section_half_width_u = 0.1;\nuniform float section_feather_u = 0.03;\n\nfloat wrap_dist(float a, float b) {\n\tfloat d = abs(a - b);\n\treturn min(d, 1.0 - d);\n}\n\nvoid fragment() {\n\tfloat d = wrap_dist(UV.x, section_center_u);\n\tfloat feather = max(section_feather_u, 0.0001);\n\tfloat mask = 1.0 - smoothstep(section_half_width_u, section_half_width_u + feather, d);\n\tfloat alpha = border_color.a * global_alpha * mask;\n\tif (alpha < 0.001) {\n\t\tdiscard;\n\t}\n\tALBEDO = border_color.rgb;\n\tALPHA = alpha;\n}\n"

	world_border_material = ShaderMaterial.new()
	world_border_material.shader = border_shader
	world_border_material.set_shader_parameter("border_color", world_border_color)
	world_border_material.set_shader_parameter("global_alpha", world_border_base_alpha)
	world_border_material.set_shader_parameter("section_center_u", 0.0)
	world_border_material.set_shader_parameter("section_half_width_u", maxf(world_border_visible_arc_degrees / 360.0, 0.001) * 0.5)
	world_border_material.set_shader_parameter("section_feather_u", maxf(world_border_arc_fade_degrees / 360.0, 0.001) * 0.5)
	world_border_mesh_instance.material_override = world_border_material

	add_child(world_border_mesh_instance)

func _snap_position_to_ground_along_up(position: Vector3, up: Vector3) -> Vector3:
	if get_world_3d() == null:
		return position

	var safe_up := _safe_normalized(up, Vector3.UP)
	var cast_offset := maxf(world_border_ground_probe_height, world_border_height)
	var ray_start := position + safe_up * cast_offset
	var ray_end := position - safe_up * cast_offset

	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = world_border_ground_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [self]

	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return position

	var hit_position: Vector3 = hit.position
	if not hit_position.is_finite():
		return position

	return hit_position

func _update_world_border_visual() -> void:
	if not world_border_enabled or world_border_mesh_instance == null:
		return

	var up := _safe_normalized(world_border_up, Vector3.UP)
	var reference := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.99 else Vector3.RIGHT
	var right := _safe_normalized(up.cross(reference), Vector3.RIGHT)
	var forward := _safe_normalized(right.cross(up), Vector3.FORWARD)
	var border_basis := Basis(right, up, forward).orthonormalized()
	var border_center := world_border_origin + up * ((world_border_height * 0.5) - world_border_ground_embed_depth)
	world_border_mesh_instance.global_transform = Transform3D(border_basis, border_center)

	var to_player := global_position - world_border_origin
	var planar_to_player := to_player - up * to_player.dot(up)
	var planar_dist := planar_to_player.length()
	var border_distance := world_border_radius - planar_dist

	if border_distance > world_border_visible_distance:
		world_border_mesh_instance.visible = false
		return

	world_border_mesh_instance.visible = true
	if world_border_material:
		var t := clampf(1.0 - (border_distance / maxf(world_border_visible_distance, 0.001)), 0.0, 1.0)
		var alpha := world_border_base_alpha * t
		var local_to_player := world_border_mesh_instance.to_local(global_position)
		local_to_player.y = 0.0
		var player_u := 0.0
		if local_to_player.length_squared() > 0.000001:
			var angle := atan2(local_to_player.z, local_to_player.x)
			player_u = fposmod((angle / TAU) + 1.0, 1.0)

		world_border_material.set_shader_parameter("border_color", world_border_color)
		world_border_material.set_shader_parameter("global_alpha", alpha)
		world_border_material.set_shader_parameter("section_center_u", player_u)
		world_border_material.set_shader_parameter("section_half_width_u", maxf(world_border_visible_arc_degrees / 360.0, 0.001) * 0.5)
		world_border_material.set_shader_parameter("section_feather_u", maxf(world_border_arc_fade_degrees / 360.0, 0.001) * 0.5)

func _enforce_world_border() -> void:
	if not world_border_enabled:
		return

	var up := _safe_normalized(world_border_up, Vector3.UP)
	var to_player := global_position - world_border_origin
	var vertical_component := up * to_player.dot(up)
	var planar_to_player := to_player - vertical_component
	var planar_dist := planar_to_player.length()
	if planar_dist <= world_border_radius:
		return

	var radial_dir := planar_to_player / maxf(planar_dist, 0.0001)
	planar_to_player = radial_dir * world_border_radius
	global_position = world_border_origin + vertical_component + planar_to_player

	var outward_speed := velocity.dot(radial_dir)
	if outward_speed > 0.0:
		velocity -= radial_dir * outward_speed

func _sync_world_border_upright_from_player(adjust_origin: bool) -> void:
	if not world_border_enabled:
		return
	world_border_up = _safe_normalized(up_direction, _safe_normalized(surface_basis.y, world_border_up))
	if adjust_origin:
		world_border_origin = _snap_position_to_ground_along_up(world_border_origin, world_border_up)
	_update_world_border_visual()

func _apply_air_strafe_bonus(horizontal_velocity: Vector3, move_direction: Vector3, up_dir: Vector3, delta: float) -> Vector3:
	if not air_strafe_enabled or move_direction == Vector3.ZERO:
		return horizontal_velocity

	var speed := horizontal_velocity.length()
	if speed < air_strafe_min_speed:
		return horizontal_velocity

	var vel_dir := horizontal_velocity / speed
	var alignment := absf(vel_dir.dot(move_direction))
	if alignment > air_strafe_input_dot_max:
		return horizontal_velocity

	var right_dir := _safe_normalized(global_basis.x - up_dir * global_basis.x.dot(up_dir), surface_basis.x)
	var side_input := absf(move_direction.dot(right_dir))
	var strafe_factor := clampf(1.0 - alignment, 0.0, 1.0) * clampf(side_input, 0.0, 1.0)
	if strafe_factor <= 0.0001:
		return horizontal_velocity

	var boosted_velocity := horizontal_velocity + move_direction * (air_strafe_bonus_acceleration * strafe_factor * delta)
	var speed_cap := maxf(speed, air_strafe_max_bonus_speed)
	var boosted_speed := boosted_velocity.length()
	if boosted_speed > speed_cap:
		boosted_velocity = boosted_velocity / boosted_speed * speed_cap
	return boosted_velocity

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
	debug_layer = CanvasLayer.new()
	debug_layer.layer = 100
	debug_layer.visible = show_debug_text
	add_child(debug_layer)

	debug_label = Label.new()
	debug_label.name = "MovementDebugLabel"
	debug_label.position = Vector2(12, 12)
	debug_label.add_theme_font_size_override("font_size", debug_font_size)
	debug_layer.add_child(debug_label)

func _setup_grapple_crosshair_ui() -> void:
	if not grapple_crosshair_enabled:
		return

	grapple_crosshair_layer = CanvasLayer.new()
	grapple_crosshair_layer.layer = 110
	add_child(grapple_crosshair_layer)

	grapple_crosshair_center = Control.new()
	grapple_crosshair_center.name = "GrappleCrosshair"
	grapple_crosshair_center.set_anchors_preset(Control.PRESET_CENTER)
	grapple_crosshair_center.offset_left = -grapple_crosshair_size * 0.5
	grapple_crosshair_center.offset_top = -grapple_crosshair_size * 0.5
	grapple_crosshair_center.offset_right = grapple_crosshair_size * 0.5
	grapple_crosshair_center.offset_bottom = grapple_crosshair_size * 0.5
	grapple_crosshair_layer.add_child(grapple_crosshair_center)

	grapple_crosshair_h = ColorRect.new()
	grapple_crosshair_h.color = grapple_crosshair_color_invalid
	grapple_crosshair_h.size = Vector2(grapple_crosshair_size, grapple_crosshair_thickness)
	grapple_crosshair_h.position = Vector2(0.0, (grapple_crosshair_size - grapple_crosshair_thickness) * 0.5)
	grapple_crosshair_center.add_child(grapple_crosshair_h)

	grapple_crosshair_v = ColorRect.new()
	grapple_crosshair_v.color = grapple_crosshair_color_invalid
	grapple_crosshair_v.size = Vector2(grapple_crosshair_thickness, grapple_crosshair_size)
	grapple_crosshair_v.position = Vector2((grapple_crosshair_size - grapple_crosshair_thickness) * 0.5, 0.0)
	grapple_crosshair_center.add_child(grapple_crosshair_v)

	if grapple_crosshair_gap > 0.0:
		var half_gap := grapple_crosshair_gap * 0.5
		grapple_crosshair_h.size.x = maxf(grapple_crosshair_size - grapple_crosshair_gap, 1.0)
		grapple_crosshair_h.position.x = half_gap
		grapple_crosshair_v.size.y = maxf(grapple_crosshair_size - grapple_crosshair_gap, 1.0)
		grapple_crosshair_v.position.y = half_gap

	grapple_indicator_root = Control.new()
	grapple_indicator_root.name = "GrappleCooldownIndicator"
	grapple_indicator_root.position = Vector2(-8.0, grapple_crosshair_size + 10.0)
	grapple_indicator_root.custom_minimum_size = Vector2(56.0, 12.0)
	grapple_crosshair_center.add_child(grapple_indicator_root)

	grapple_indicator_icon = Label.new()
	grapple_indicator_icon.name = "GrappleIcon"
	grapple_indicator_icon.position = Vector2(0.0, -2.0)
	grapple_indicator_icon.size = Vector2(14.0, 12.0)
	grapple_indicator_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grapple_indicator_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grapple_indicator_icon.add_theme_font_size_override("font_size", 12)
	grapple_indicator_icon.text = "⛓"
	grapple_indicator_root.add_child(grapple_indicator_icon)

	grapple_indicator_bar_bg = ColorRect.new()
	grapple_indicator_bar_bg.name = "CooldownBarBg"
	grapple_indicator_bar_bg.position = Vector2(16.0, 3.0)
	grapple_indicator_bar_bg.size = Vector2(40.0, 6.0)
	grapple_indicator_bar_bg.color = Color(0.06, 0.08, 0.1, 0.7)
	grapple_indicator_root.add_child(grapple_indicator_bar_bg)

	grapple_indicator_bar_fill = ColorRect.new()
	grapple_indicator_bar_fill.name = "CooldownBarFill"
	grapple_indicator_bar_fill.position = Vector2.ZERO
	grapple_indicator_bar_fill.size = Vector2(40.0, 6.0)
	grapple_indicator_bar_fill.color = grapple_crosshair_color_valid
	grapple_indicator_bar_bg.add_child(grapple_indicator_bar_fill)

func _set_grapple_indicator(color: Color, fill_ratio: float) -> void:
	if grapple_indicator_icon:
		grapple_indicator_icon.modulate = color
	if grapple_indicator_bar_fill:
		grapple_indicator_bar_fill.color = color
		var ratio := clampf(fill_ratio, 0.0, 1.0)
		grapple_indicator_bar_fill.size.x = 40.0 * ratio

func _set_crosshair_color(color: Color) -> void:
	if grapple_crosshair_h:
		grapple_crosshair_h.color = color
	if grapple_crosshair_v:
		grapple_crosshair_v.color = color

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

func _update_grapple_crosshair() -> void:
	if not grapple_crosshair_enabled or grapple_crosshair_layer == null:
		return

	var should_show := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and camera != null and camera.is_inside_tree() and grapple_enabled
	grapple_crosshair_layer.visible = should_show
	if not should_show:
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
		return

	var origin := camera.global_position
	var center_dir := _get_center_ray_direction()
	var hit := _cast_grapple_ray(origin, center_dir)
	var can_grapple := not hit.is_empty()
	_set_crosshair_color(grapple_crosshair_color_valid if can_grapple else grapple_crosshair_color_invalid)
	_set_grapple_indicator(grapple_crosshair_color_valid, 1.0)

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
	if not direction.is_finite() or direction.length_squared() < 0.000001:
		return {}

	if get_world_3d() == null:
		return {}

	var to := origin + direction.normalized() * grapple_max_distance
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	query.exclude = [self]
	query.collision_mask = grapple_collision_mask
	query.hit_back_faces = false
	query.hit_from_inside = false
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {}

	var hit_pos: Vector3 = hit.position
	if not hit_pos.is_finite():
		return {}

	var hit_distance: float = origin.distance_to(hit_pos)
	if hit_distance < grapple_min_hit_distance:
		return {}

	var hit_normal: Vector3 = hit.normal
	if hit_normal.is_finite() and hit_normal.length_squared() > 0.000001:
		var ray_dir := direction.normalized()
		if hit_normal.dot(ray_dir) > -0.02:
			return {}

	return hit

func _find_best_grapple_hit() -> Dictionary:
	if camera == null or not camera.is_inside_tree():
		return {}

	var origin := camera.global_position
	var center_dir := _get_center_ray_direction()
	return _cast_grapple_ray(origin, center_dir)

func _try_start_grapple() -> void:
	if not grapple_enabled or camera == null or not camera.is_inside_tree() or grapple_rehook_timer > 0.0 or grapple_cooldown_timer > 0.0:
		return

	var origin := camera.global_position
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
	if not globe_node or not globe_node.is_inside_tree():
		return surface_basis
	
	var cam_ecef_pos: Vector3
	if globe_node.origin_type == CesiumGeoreference.OriginType.CartographicOrigin:
		cam_ecef_pos = Vector3(globe_node.ecefX, globe_node.ecefY, globe_node.ecefZ)
	else:
		cam_ecef_pos = globe_node.get_tx_engine_to_ecef() * global_position
	
	var up: Vector3 = globe_node.get_normal_at_surface_pos(cam_ecef_pos)
	if not up.is_finite() or up.length_squared() < 0.000001:
		return surface_basis
	up = up.normalized()
	
	var reference := -global_basis.z
	
	# Avoid colinear reference vectors (both same and opposite direction).
	if absf(up.dot(reference)) > 0.99:
		reference = global_basis.x
	
	# Calculate right vector using cross product.
	var right := up.cross(reference)
	if right.length_squared() < 0.000001:
		reference = Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.99 else Vector3.RIGHT
		right = up.cross(reference)
		if right.length_squared() < 0.000001:
			return surface_basis
	right = _safe_normalized(right, surface_basis.x)
	
	# Calculate forward vector using cross product of right and up.
	var forward := right.cross(up)
	if forward.length_squared() < 0.000001:
		return surface_basis
	forward = _safe_normalized(forward, -surface_basis.z)
	
	var result := Basis(right, up, -forward)
	if not result.x.is_finite() or not result.y.is_finite() or not result.z.is_finite():
		return surface_basis
	if absf(result.determinant()) < 0.000001:
		return surface_basis
	return result

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
	_update_grapple_crosshair()

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
