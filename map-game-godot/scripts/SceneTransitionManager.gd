extends Node

var _transition_in_progress: bool = false
const _LOG_FILE_PATH := "user://transition_debug.log"
const _QUARANTINE_ROOT_NAME := "_CesiumTransitionQuarantine"
const _FALLBACK_SCENE_PATH := "res://main_menu.tscn"

func request_transition(target_scene_path: String, show_loading_overlay: bool = false, mouse_mode: Input.MouseMode = Input.MOUSE_MODE_VISIBLE) -> bool:
	_log("request_transition target=%s in_progress=%s" % [target_scene_path, str(_transition_in_progress)])
	if _transition_in_progress or target_scene_path.is_empty():
		_log("request rejected")
		return false
	_stabilize_quarantine()
	_transition_in_progress = true
	call_deferred("_perform_transition", target_scene_path, show_loading_overlay, mouse_mode)
	return true

func _perform_transition(target_scene_path: String, show_loading_overlay: bool, mouse_mode: Input.MouseMode) -> void:
	_log("perform_transition begin target=%s" % target_scene_path)
	var tree := get_tree()
	if tree == null:
		_log("perform_transition aborted: missing tree")
		_transition_in_progress = false
		return

	Input.mouse_mode = mouse_mode
	Input.flush_buffered_events()

	var state := get_node_or_null("/root/GameState")
	if state != null and state.has_method("set"):
		state.set("show_world_loading_overlay", show_loading_overlay)
		_log("state updated show_world_loading_overlay=%s" % str(show_loading_overlay))

	_prepare_cesium_for_scene_exit(tree.current_scene)
	_log("cesium pre-exit completed")

	await tree.process_frame
	await tree.process_frame
	await tree.process_frame
	Input.flush_buffered_events()
	_log("frame settle complete")

	var error := tree.change_scene_to_file(target_scene_path)
	_log("change_scene_to_file target=%s error=%d" % [target_scene_path, error])
	if error != OK:
		push_warning("SceneTransitionManager failed to load: %s (error %d)" % [target_scene_path, error])
		if target_scene_path != _FALLBACK_SCENE_PATH:
			await tree.process_frame
			var fallback_error := tree.change_scene_to_file(_FALLBACK_SCENE_PATH)
			_log("fallback change_scene_to_file target=%s error=%d" % [_FALLBACK_SCENE_PATH, fallback_error])

	await tree.process_frame
	await tree.process_frame
	_stabilize_quarantine()

	_transition_in_progress = false
	_log("perform_transition end")

func _prepare_cesium_for_scene_exit(current_scene: Node) -> void:
	if current_scene == null or not is_instance_valid(current_scene):
		_log("prepare_cesium skipped: invalid scene")
		return

	var tree := get_tree()
	if tree == null:
		_log("prepare_cesium skipped: missing tree")
		return
	var quarantine_root := _get_quarantine_root(tree)

	var cameras := current_scene.find_children("*", "AbstractCesiumCamera", true, false)
	_log("prepare_cesium cameras=%d" % cameras.size())
	var moved_cameras := 0
	for camera_node in cameras:
		if camera_node == null or not is_instance_valid(camera_node):
			continue
		camera_node.set_process(false)
		camera_node.set_physics_process(false)
		if _quarantine_node(camera_node, current_scene, quarantine_root):
			moved_cameras += 1

	var tilesets := current_scene.find_children("*", "Cesium3DTileset", true, false)
	_log("prepare_cesium tilesets=%d" % tilesets.size())
	for tileset in tilesets:
		if tileset == null or not is_instance_valid(tileset):
			continue
		tileset.set_process(false)
		tileset.set_physics_process(false)

	var georef := current_scene.get_node_or_null("CesiumGeoreference")
	if georef != null and is_instance_valid(georef):
		georef.set_process(false)
		georef.set_physics_process(false)
		var moved_georef := _quarantine_node(georef, current_scene, quarantine_root)
		_log("prepare_cesium georef process disabled moved=%s" % str(moved_georef))

	_log("prepare_cesium moved_cameras=%d" % moved_cameras)

func _get_quarantine_root(tree: SceneTree) -> Node:
	var root := tree.root
	var existing := root.get_node_or_null(_QUARANTINE_ROOT_NAME)
	if existing != null:
		return existing

	var quarantine := Node.new()
	quarantine.name = _QUARANTINE_ROOT_NAME
	root.add_child(quarantine)
	return quarantine

func _quarantine_node(node: Node, scene_root: Node, quarantine_root: Node) -> bool:
	if node == null or scene_root == null or quarantine_root == null:
		return false
	if not is_instance_valid(node):
		return false
	if not scene_root.is_ancestor_of(node):
		return false
	if node.get_parent() == null:
		return false

	node.get_parent().remove_child(node)
	quarantine_root.add_child(node)
	node.set_process(false)
	node.set_physics_process(false)
	node.set_process_input(false)
	if node is Node3D:
		(node as Node3D).visible = false
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	return true

func _stabilize_quarantine() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var root := tree.root
	if root == null:
		return

	var quarantine_root := root.get_node_or_null(_QUARANTINE_ROOT_NAME)
	if quarantine_root == null:
		return

	var children := quarantine_root.get_children()
	if children.is_empty():
		return

	_log("stabilize_quarantine children=%d" % children.size())
	for child in children:
		if child == null or not is_instance_valid(child):
			continue
		child.set_process(false)
		child.set_physics_process(false)
		child.set_process_input(false)
		if child is Node3D:
			(child as Node3D).visible = false
		if child is CanvasItem:
			(child as CanvasItem).visible = false

func _log(message: String) -> void:
	var line := "[%s] %s\n" % [Time.get_datetime_string_from_system(), message]
	print("[SceneTransitionManager] %s" % message)
	var file := FileAccess.open(_LOG_FILE_PATH, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_string(line)