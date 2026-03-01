extends Node3D

@export var loading_overlay_scene: PackedScene = preload("res://ui/world_loading_overlay.tscn")
@export var world_tileset_path: NodePath = NodePath("CesiumGeoreference/Google Photorealistic 3D Tiles")
@export var min_loading_hold_seconds: float = 1.2
@export var max_loading_wait_seconds: float = 6.0
@export var fps_counter_enabled: bool = true
@export var fps_counter_update_interval: float = 0.2

var _overlay_layer: CanvasLayer
var _overlay_label: Label
var _overlay_progress: ProgressBar
var _overlay_timer: float = 0.0
var _overlay_duration: float = 0.0
var _overlay_active: bool = false
var _watermark_enforce_timer: float = 0.0
var _credit_canvas_items: Array[CanvasItem] = []
var _tileset_node: Node
var _fps_layer: CanvasLayer
var _fps_label: Label
var _fps_update_timer: float = 0.0

func _cache_cesium_credit_nodes() -> void:
	var root := get_tree().root if get_tree() else null
	if root == null:
		return

	_credit_canvas_items.clear()
	var credit_nodes := root.find_children("*", "CesiumGDCreditSystem", true, false)
	for node in credit_nodes:
		if node and node is CanvasItem:
			_credit_canvas_items.append(node)

func _hide_cached_cesium_credit_nodes() -> void:
	for i in range(_credit_canvas_items.size() - 1, -1, -1):
		var item := _credit_canvas_items[i]
		if item == null or not is_instance_valid(item):
			_credit_canvas_items.remove_at(i)
			continue
		item.visible = false

func _disable_cesium_watermark() -> void:
	if ClassDB.class_exists("CesiumGDCreditSystem"):
		CesiumGDCreditSystem.turn_off()
	if _credit_canvas_items.is_empty():
		_cache_cesium_credit_nodes()
	_hide_cached_cesium_credit_nodes()

func _enforce_cesium_watermark_hidden(delta: float) -> void:
	_watermark_enforce_timer += delta
	if _watermark_enforce_timer < 0.5:
		return
	_watermark_enforce_timer = 0.0
	if _credit_canvas_items.is_empty():
		_cache_cesium_credit_nodes()
	_disable_cesium_watermark()

func _game_state() -> Node:
	return get_node_or_null("/root/GameState")

func _ready() -> void:
	_stabilize_transition_quarantine()
	_cache_cesium_credit_nodes()
	_disable_cesium_watermark()
	_setup_fps_counter()
	if not has_node("CesiumGeoreference"):
		return

	var georef: CesiumGeoreference = $CesiumGeoreference
	_tileset_node = get_node_or_null(world_tileset_path)
	var city_data: Dictionary = {}
	var state := _game_state()
	if state != null and state.has_method("get_selected_city_data"):
		city_data = state.get_selected_city_data()
	georef.longitude = city_data.get("longitude", georef.longitude)
	georef.latitude = city_data.get("latitude", georef.latitude)
	georef.altitude = city_data.get("altitude", georef.altitude)

	if state != null and bool(state.get("show_world_loading_overlay")):
		_overlay_duration = clampf(float(state.get("world_loading_overlay_seconds")), min_loading_hold_seconds, max_loading_wait_seconds)
		_overlay_active = true
		_overlay_timer = 0.0
		state.set("show_world_loading_overlay", false)
		_create_loading_overlay()
		_set_player_locked(true)

func _stabilize_transition_quarantine() -> void:
	var root := get_tree().root if get_tree() else null
	if root == null:
		return
	var quarantine := root.get_node_or_null("_CesiumTransitionQuarantine")
	if quarantine == null:
		return

	for child in quarantine.get_children():
		if child == null or not is_instance_valid(child):
			continue
		child.set_process(false)
		child.set_physics_process(false)
		child.set_process_input(false)
		if child is Node3D:
			(child as Node3D).visible = false
		if child is CanvasItem:
			(child as CanvasItem).visible = false

func _process(delta: float) -> void:
	_update_fps_counter(delta)
	_enforce_cesium_watermark_hidden(delta)

	if not _overlay_active:
		return

	_overlay_timer += delta
	var ratio := clampf(_overlay_timer / maxf(_overlay_duration, 0.001), 0.0, 1.0)
	if _is_tileset_initially_ready() and _overlay_timer >= min_loading_hold_seconds:
		ratio = 1.0
	if _overlay_progress:
		_overlay_progress.value = ratio * 100.0
	if _overlay_label:
		_overlay_label.text = "Loading city... %d%%" % int(ratio * 100.0)

	if ratio >= 1.0 or _overlay_timer >= max_loading_wait_seconds:
		_overlay_active = false
		_set_player_locked(false)
		if _overlay_layer:
			_overlay_layer.queue_free()
			_overlay_layer = null

func _is_tileset_initially_ready() -> bool:
	if _tileset_node == null or not is_instance_valid(_tileset_node):
		return false
	if _tileset_node.has_method("is_initial_loading_finished"):
		return bool(_tileset_node.call("is_initial_loading_finished"))
	return false

func _setup_fps_counter() -> void:
	if not fps_counter_enabled:
		return
	_fps_layer = get_node_or_null("FpsLayer") as CanvasLayer
	if _fps_layer == null:
		push_warning("Missing scene node: FpsLayer")
		return

	_fps_label = get_node_or_null("FpsLayer/FpsCounter") as Label
	if _fps_label == null:
		push_warning("Missing scene node: FpsLayer/FpsCounter")
		return

func _update_fps_counter(delta: float) -> void:
	if _fps_label == null:
		return
	_fps_update_timer += delta
	if _fps_update_timer < maxf(fps_counter_update_interval, 0.05):
		return
	_fps_update_timer = 0.0
	var fps := Engine.get_frames_per_second()
	_fps_label.text = "FPS: %d" % fps

func _set_player_locked(locked: bool) -> void:
	if not has_node("Player"):
		return
	var player := $Player
	player.set_process(not locked)
	player.set_physics_process(not locked)
	player.set_process_input(not locked)

func _create_loading_overlay() -> void:
	if loading_overlay_scene == null:
		push_warning("Missing loading overlay scene resource")
		return

	var overlay_instance := loading_overlay_scene.instantiate()
	if overlay_instance is CanvasLayer:
		_overlay_layer = overlay_instance as CanvasLayer
		add_child(_overlay_layer)
	else:
		push_warning("Loading overlay scene root must be a CanvasLayer")
		return

	_overlay_label = _overlay_layer.get_node_or_null("Root/CenterContainer/VBoxContainer/StatusLabel") as Label
	_overlay_progress = _overlay_layer.get_node_or_null("Root/CenterContainer/VBoxContainer/ProgressBar") as ProgressBar
	if _overlay_label == null:
		push_warning("Missing overlay node: Root/CenterContainer/VBoxContainer/StatusLabel")
	if _overlay_progress == null:
		push_warning("Missing overlay node: Root/CenterContainer/VBoxContainer/ProgressBar")

	if _overlay_progress:
		_overlay_progress.value = 0.0
