class_name PlayerBorderModule
extends RefCounted

static func _safe_normalized(v: Vector3, fallback: Vector3) -> Vector3:
	if not v.is_finite() or v.length_squared() < 0.000001:
		return fallback
	return v.normalized()

static func setup_world_border_visual(host: Node3D, world_border_enabled: bool, world_border_radius: float, world_border_height: float, world_border_color: Color, world_border_base_alpha: float, world_border_visible_arc_degrees: float, world_border_arc_fade_degrees: float) -> Dictionary:
	if not world_border_enabled:
		return {}

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "WorldBorder"
	mesh_instance.top_level = true
	mesh_instance.visible = false

	var mesh := CylinderMesh.new()
	mesh.top_radius = world_border_radius
	mesh.bottom_radius = world_border_radius
	mesh.height = world_border_height
	mesh.radial_segments = 96
	mesh_instance.mesh = mesh

	var border_shader := Shader.new()
	border_shader.code = "shader_type spatial;\nrender_mode unshaded, cull_disabled, blend_mix;\n\nuniform vec4 border_color : source_color = vec4(0.25, 0.9, 1.0, 1.0);\nuniform float global_alpha = 0.3;\nuniform float section_center_u = 0.0;\nuniform float section_half_width_u = 0.1;\nuniform float section_feather_u = 0.03;\n\nfloat wrap_dist(float a, float b) {\n\tfloat d = abs(a - b);\n\treturn min(d, 1.0 - d);\n}\n\nvoid fragment() {\n\tfloat d = wrap_dist(UV.x, section_center_u);\n\tfloat feather = max(section_feather_u, 0.0001);\n\tfloat mask = 1.0 - smoothstep(section_half_width_u, section_half_width_u + feather, d);\n\tfloat alpha = border_color.a * global_alpha * mask;\n\tif (alpha < 0.001) {\n\t\tdiscard;\n\t}\n\tALBEDO = border_color.rgb;\n\tALPHA = alpha;\n}\n"

	var material := ShaderMaterial.new()
	material.shader = border_shader
	material.set_shader_parameter("border_color", world_border_color)
	material.set_shader_parameter("global_alpha", world_border_base_alpha)
	material.set_shader_parameter("section_center_u", 0.0)
	material.set_shader_parameter("section_half_width_u", maxf(world_border_visible_arc_degrees / 360.0, 0.001) * 0.5)
	material.set_shader_parameter("section_feather_u", maxf(world_border_arc_fade_degrees / 360.0, 0.001) * 0.5)
	mesh_instance.material_override = material

	host.add_child(mesh_instance)
	return {"mesh_instance": mesh_instance, "material": material}

static func snap_position_to_ground_along_up(host: Node3D, sample_position: Vector3, up: Vector3, world_border_ground_probe_height: float, world_border_height: float, world_border_ground_collision_mask: int, self_node: Node) -> Vector3:
	if host.get_world_3d() == null:
		return sample_position

	var safe_up := _safe_normalized(up, Vector3.UP)
	var cast_offset := maxf(world_border_ground_probe_height, world_border_height)
	var ray_start := sample_position + safe_up * cast_offset
	var ray_end := sample_position - safe_up * cast_offset

	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.collision_mask = world_border_ground_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = [self_node]

	var hit := host.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return sample_position

	var hit_position: Vector3 = hit.position
	if not hit_position.is_finite():
		return sample_position

	return hit_position

static func update_world_border_visual(mesh_instance: MeshInstance3D, material: ShaderMaterial, world_border_enabled: bool, world_border_up: Vector3, world_border_origin: Vector3, world_border_height: float, world_border_ground_embed_depth: float, world_border_radius: float, world_border_visible_distance: float, world_border_base_alpha: float, world_border_color: Color, world_border_visible_arc_degrees: float, world_border_arc_fade_degrees: float, player_global_position: Vector3) -> void:
	if not world_border_enabled or mesh_instance == null:
		return

	var up := _safe_normalized(world_border_up, Vector3.UP)
	var ref_dir := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.99 else Vector3.RIGHT
	var right := _safe_normalized(up.cross(ref_dir), Vector3.RIGHT)
	var forward := _safe_normalized(right.cross(up), Vector3.FORWARD)
	var border_basis := Basis(right, up, forward).orthonormalized()
	var border_center := world_border_origin + up * ((world_border_height * 0.5) - world_border_ground_embed_depth)
	mesh_instance.global_transform = Transform3D(border_basis, border_center)

	var to_player := player_global_position - world_border_origin
	var planar_to_player := to_player - up * to_player.dot(up)
	var planar_dist := planar_to_player.length()
	var border_distance := world_border_radius - planar_dist

	if border_distance > world_border_visible_distance:
		mesh_instance.visible = false
		return

	mesh_instance.visible = true
	if material:
		var t := clampf(1.0 - (border_distance / maxf(world_border_visible_distance, 0.001)), 0.0, 1.0)
		var alpha := world_border_base_alpha * t
		var local_to_player := mesh_instance.to_local(player_global_position)
		local_to_player.y = 0.0
		var player_u := 0.0
		if local_to_player.length_squared() > 0.000001:
			var angle := atan2(local_to_player.z, local_to_player.x)
			player_u = fposmod((angle / TAU) + 1.0, 1.0)

		material.set_shader_parameter("border_color", world_border_color)
		material.set_shader_parameter("global_alpha", alpha)
		material.set_shader_parameter("section_center_u", player_u)
		material.set_shader_parameter("section_half_width_u", maxf(world_border_visible_arc_degrees / 360.0, 0.001) * 0.5)
		material.set_shader_parameter("section_feather_u", maxf(world_border_arc_fade_degrees / 360.0, 0.001) * 0.5)

static func enforce_world_border(world_border_enabled: bool, world_border_up: Vector3, world_border_origin: Vector3, world_border_radius: float, player_global_position: Vector3, velocity: Vector3) -> Dictionary:
	if not world_border_enabled:
		return {"position": player_global_position, "velocity": velocity}

	var up := _safe_normalized(world_border_up, Vector3.UP)
	var to_player := player_global_position - world_border_origin
	var vertical_component := up * to_player.dot(up)
	var planar_to_player := to_player - vertical_component
	var planar_dist := planar_to_player.length()
	if planar_dist <= world_border_radius:
		return {"position": player_global_position, "velocity": velocity}

	var radial_dir := planar_to_player / maxf(planar_dist, 0.0001)
	planar_to_player = radial_dir * world_border_radius
	var corrected_position := world_border_origin + vertical_component + planar_to_player

	var corrected_velocity := velocity
	var outward_speed := corrected_velocity.dot(radial_dir)
	if outward_speed > 0.0:
		corrected_velocity -= radial_dir * outward_speed

	return {"position": corrected_position, "velocity": corrected_velocity}
