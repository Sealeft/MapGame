class_name PlayerMovementModule
extends RefCounted

static func _safe_normalized(v: Vector3, fallback: Vector3) -> Vector3:
	if not v.is_finite() or v.length_squared() < 0.000001:
		return fallback
	return v.normalized()

static func apply_air_strafe_bonus(horizontal_velocity: Vector3, move_direction: Vector3, up_dir: Vector3, delta: float, air_strafe_enabled: bool, air_strafe_min_speed: float, air_strafe_input_dot_max: float, air_strafe_bonus_acceleration: float, air_strafe_max_bonus_speed: float, global_basis: Basis, surface_basis: Basis) -> Vector3:
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

static func calculate_surface_basis(globe_node: CesiumGeoreference, surface_basis: Basis, global_basis: Basis, global_position: Vector3) -> Basis:
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

	var ref_dir := -global_basis.z
	if absf(up.dot(ref_dir)) > 0.99:
		ref_dir = global_basis.x

	var right := up.cross(ref_dir)
	if right.length_squared() < 0.000001:
		ref_dir = Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.99 else Vector3.RIGHT
		right = up.cross(ref_dir)
		if right.length_squared() < 0.000001:
			return surface_basis
	right = _safe_normalized(right, surface_basis.x)

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
