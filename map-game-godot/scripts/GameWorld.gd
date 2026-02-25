extends Node3D

@export var loading_overlay_scene: PackedScene = preload("res://ui/world_loading_overlay.tscn")

var _overlay_layer: CanvasLayer
var _overlay_label: Label
var _overlay_progress: ProgressBar
var _overlay_timer: float = 0.0
var _overlay_duration: float = 0.0
var _overlay_active: bool = false
var _player_locked: bool = false
var _watermark_enforce_timer: float = 0.0
var _credit_canvas_items: Array[CanvasItem] = []

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
	return get_node("/root/GameState")

func _ready() -> void:
	_cache_cesium_credit_nodes()
	_disable_cesium_watermark()
	if not has_node("CesiumGeoreference"):
		return

	var georef: CesiumGeoreference = $CesiumGeoreference
	var city_data: Dictionary = _game_state().get_selected_city_data()
	georef.longitude = city_data.get("longitude", georef.longitude)
	georef.latitude = city_data.get("latitude", georef.latitude)
	georef.altitude = city_data.get("altitude", georef.altitude)

	if _game_state().show_world_loading_overlay:
		_overlay_duration = maxf(_game_state().world_loading_overlay_seconds, 0.1)
		_overlay_active = true
		_overlay_timer = 0.0
		_game_state().show_world_loading_overlay = false
		_create_loading_overlay()
		_set_player_locked(true)

func _process(delta: float) -> void:
	_enforce_cesium_watermark_hidden(delta)

	if not _overlay_active:
		return

	_overlay_timer += delta
	var ratio := clampf(_overlay_timer / _overlay_duration, 0.0, 1.0)
	if _overlay_progress:
		_overlay_progress.value = ratio * 100.0
	if _overlay_label:
		_overlay_label.text = "Loading city... %d%%" % int(ratio * 100.0)

	if _overlay_timer >= _overlay_duration:
		_overlay_active = false
		_set_player_locked(false)
		if _overlay_layer:
			_overlay_layer.queue_free()
			_overlay_layer = null

func _set_player_locked(locked: bool) -> void:
	if not has_node("Player"):
		return
	var player := $Player
	player.set_process(not locked)
	player.set_physics_process(not locked)
	player.set_process_input(not locked)
	_player_locked = locked

func _create_loading_overlay() -> void:
	if loading_overlay_scene != null:
		var overlay_instance := loading_overlay_scene.instantiate()
		if overlay_instance is CanvasLayer:
			_overlay_layer = overlay_instance as CanvasLayer
			add_child(_overlay_layer)

	if _overlay_layer == null:
		_overlay_layer = CanvasLayer.new()
		_overlay_layer.layer = 200
		add_child(_overlay_layer)

	_overlay_label = _overlay_layer.get_node_or_null("Root/CenterContainer/VBoxContainer/StatusLabel") as Label
	_overlay_progress = _overlay_layer.get_node_or_null("Root/CenterContainer/VBoxContainer/ProgressBar") as ProgressBar

	if _overlay_label == null:
		_overlay_label = Label.new()
		_overlay_label.text = "Loading city..."
		_overlay_layer.add_child(_overlay_label)

	if _overlay_progress == null:
		_overlay_progress = ProgressBar.new()
		_overlay_progress.max_value = 100.0
		_overlay_progress.show_percentage = false
		_overlay_layer.add_child(_overlay_progress)

	_overlay_progress.value = 0.0
