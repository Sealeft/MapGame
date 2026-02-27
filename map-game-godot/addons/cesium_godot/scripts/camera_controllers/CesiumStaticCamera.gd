@icon("res://addons/cesium_godot/resources/icons/video.svg")

class_name CesiumStaticCamera extends AbstractCesiumCamera

## A Cesium camera that updates tilesets but doesn't handle any movement or rotation.
## Perfect for use as a child of a CharacterBody3D or other controller that handles movement.

@export_range(0.001, 1000.0, 0.001, "or_greater")
var static_near_plane: float = 0.5

@export_range(1.0, 1000000000.0, 1.0, "or_greater")
var static_far_plane: float = 200000.0

func _ready() -> void:
	super()
	var requested_near := maxf(static_near_plane, 0.001)
	var requested_far := maxf(static_far_plane, requested_near + 0.001)

	if requested_far <= requested_near:
		push_warning("CesiumStaticCamera: static_far_plane must be larger than static_near_plane. Auto-adjusting far.")
		requested_far = requested_near + 1.0

	self.near = requested_near
	self.far = requested_far
	# Correct the camera orientation to account for Cesium's coordinate system
	if globe_node and globe_node.origin_type == CesiumGeoreference.CartographicOrigin:
		# The globe has a transform that rotates the world, we need to counter-rotate the camera
		# to keep it upright relative to the player's local space
		pass

func _process(delta: float) -> void:
	if _is_exiting_tree or is_queued_for_deletion():
		return
	if not is_inside_tree() or not is_node_ready() or get_world_3d() == null:
		return
	if globe_node == null or not is_instance_valid(globe_node) or not globe_node.is_inside_tree() or globe_node.is_queued_for_deletion() or not globe_node.is_node_ready() or globe_node.get_world_3d() == null:
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null or not tree.current_scene.is_ancestor_of(self) or not tree.current_scene.is_ancestor_of(globe_node):
		return

	super(delta)
	if _is_exiting_tree or is_queued_for_deletion():
		return
	
	# Keep camera oriented correctly in Cesium's rotated coordinate system
	if globe_node and is_inside_tree() and globe_node.is_inside_tree() and not globe_node.is_queued_for_deletion():
		var parent_body = get_parent()
		if parent_body is CharacterBody3D:
			# Get the surface normal at our position
			var cam_ecef_pos : Vector3
			if globe_node.origin_type == CesiumGeoreference.CartographicOrigin:
				cam_ecef_pos = Vector3(globe_node.ecefX, globe_node.ecefY, globe_node.ecefZ)
			else:
				cam_ecef_pos = globe_node.get_tx_engine_to_ecef() * global_position
			
			var up : Vector3 = globe_node.get_normal_at_surface_pos(cam_ecef_pos)
			
			# Align parent's up with surface normal
			var current_up = parent_body.global_basis.y
			if current_up.dot(up) < 0.999:  # Only adjust if not already aligned
				var correction = current_up.cross(up)
				if correction.length() > 0.001:
					var angle = current_up.angle_to(up)
					parent_body.global_rotate(correction.normalized(), angle * 0.1)  # Smooth correction
