class_name AbstractCesiumCamera extends Camera3D

@export
var globe_node : CesiumGeoreference

@export
var tilesets : Array[Cesium3DTileset]

@onready
var post_process_mesh = preload("res://addons/cesium_godot/visuals/post-process.tscn")

@export
var render_atmosphere : bool

var atmosphere_manager: AtmosphereManager

var last_hit_distance: float
var _is_exiting_tree: bool = false

const RADII := 6378137.0
const ACCEPTABLE_NEAR_PLANE := 9

func find_directional_light(node: Node) -> DirectionalLight3D:
	if node is DirectionalLight3D:
		return node

	for child in node.get_children():
		var light = find_directional_light(child)
		if light:
			return light

	return null

func _ready() -> void:
	# This is a workaround for the fact that you can't detect double precision builds in GDScript
	# but you probably aren't using TrueOrigin in a single precision build
	if self.globe_node.origin_type == CesiumGeoreference.CartographicOrigin:
		self.far = 35358652.0
		self.near = ACCEPTABLE_NEAR_PLANE
	else:
		self.far = 149597870700.0 + 3*1392700000.0
		# Get the ecef
		var ecef_pos := Vector3(self.globe_node.ecefX, self.globe_node.ecefY, self.globe_node.ecefZ)
		self.global_position = self.globe_node.get_tx_ecef_to_engine() * ecef_pos

	if self.render_atmosphere:
		self._load_atmosphere()

	if not is_finite(self.near) or self.near < 0.001:
		self.near = 0.001
	if not is_finite(self.far) or self.far <= self.near:
		self.far = self.near + 1000.0



func _load_atmosphere() -> void:
	self.atmosphere_manager = AtmosphereManager.new()
	self.atmosphere_manager.display_atmosphere = true
	self.atmosphere_manager.globe = self.globe_node
	var atmosphereNode = self.post_process_mesh.instantiate()
	self.atmosphere_manager.mesh_atmosphere = atmosphereNode
	self.atmosphere_manager.camera = self
	self.atmosphere_manager.sun = self.find_directional_light(self.get_tree().current_scene)
	if self.atmosphere_manager.sun == null:
		push_warning("Atmosphere couldn't find a directional light to use as the sun!")
		return
	self.add_child(atmosphereNode)
	self.add_child(self.atmosphere_manager)


func _process(_delta: float) -> void:
	if _is_exiting_tree or is_queued_for_deletion():
		return
	if not is_inside_tree() or not is_node_ready():
		return
	if get_world_3d() == null:
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null or not tree.current_scene.is_ancestor_of(self):
		return
	if globe_node == null or not is_instance_valid(globe_node) or not globe_node.is_inside_tree() or globe_node.is_queued_for_deletion() or not globe_node.is_node_ready():
		return
	if globe_node.get_world_3d() == null:
		return
	if not tree.current_scene.is_ancestor_of(globe_node):
		return
	_update_tilesets()


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_is_exiting_tree = false
		set_process(true)
	elif what == NOTIFICATION_EXIT_TREE:
		_is_exiting_tree = true
		set_process(false)


func _update_tilesets() -> void:
	if _is_exiting_tree or is_queued_for_deletion():
		return
	if not is_inside_tree() or not is_node_ready():
		return
	if get_world_3d() == null:
		return
	var tree := get_tree()
	if tree == null or tree.current_scene == null or not tree.current_scene.is_ancestor_of(self):
		return
	if globe_node == null or not is_instance_valid(globe_node) or not globe_node.is_inside_tree() or globe_node.is_queued_for_deletion() or not globe_node.is_node_ready():
		return
	if globe_node.get_world_3d() == null:
		return
	if not tree.current_scene.is_ancestor_of(globe_node):
		return
	if not global_position.is_finite() or not global_basis.x.is_finite() or not global_basis.y.is_finite() or not global_basis.z.is_finite():
		return
	var camera_engine_xform := Transform3D(self.global_basis, self.global_position)
	var camera_xform := self.globe_node.get_tx_engine_to_ecef() * camera_engine_xform
	for tileset in self.tilesets:
		if (tileset == null): continue
		if not is_instance_valid(tileset) or not tileset.is_inside_tree() or tileset.is_queued_for_deletion() or not tileset.is_node_ready():
			continue
		if tileset.get_world_3d() == null:
			continue
		if not tree.current_scene.is_ancestor_of(tileset):
			continue
		if not is_inside_tree() or _is_exiting_tree or is_queued_for_deletion() or get_world_3d() == null:
			return
		if not tileset.is_inside_tree() or tileset.is_queued_for_deletion() or tileset.get_world_3d() == null:
			continue
		tileset.update_tileset(camera_xform)
