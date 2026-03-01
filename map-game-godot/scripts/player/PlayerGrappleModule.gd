class_name PlayerGrappleModule
extends RefCounted

static func cast_grapple_ray(host: Node3D, self_node: Node, origin: Vector3, direction: Vector3, max_distance: float, min_hit_distance: float, collision_mask: int) -> Dictionary:
	if not direction.is_finite() or direction.length_squared() < 0.000001:
		return {}

	if host.get_world_3d() == null:
		return {}

	var to := origin + direction.normalized() * max_distance
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	query.exclude = [self_node]
	query.collision_mask = collision_mask
	query.hit_back_faces = false
	query.hit_from_inside = false
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit: Dictionary = host.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {}

	var hit_pos: Vector3 = hit.position
	if not hit_pos.is_finite():
		return {}

	var hit_distance: float = origin.distance_to(hit_pos)
	if hit_distance < min_hit_distance:
		return {}

	var hit_normal: Vector3 = hit.normal
	if hit_normal.is_finite() and hit_normal.length_squared() > 0.000001:
		var ray_dir := direction.normalized()
		if hit_normal.dot(ray_dir) > -0.02:
			return {}

	return hit
