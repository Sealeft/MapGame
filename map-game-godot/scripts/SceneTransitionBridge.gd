extends Control

@export var fallback_scene_path: String = "res://main_menu.tscn"
@export var transition_delay_seconds: float = 0.05

func _game_state() -> Node:
	return get_node_or_null("/root/GameState")

func _ready() -> void:
	Input.flush_buffered_events()
	call_deferred("_perform_transition")

func _perform_transition() -> void:
	var tree := get_tree()
	if tree == null:
		return

	if transition_delay_seconds > 0.0:
		await tree.create_timer(transition_delay_seconds).timeout

	await tree.process_frame
	await tree.process_frame
	await tree.process_frame
	Input.flush_buffered_events()

	var target := fallback_scene_path
	var state := _game_state()
	if state != null and state.has_method("get"):
		var pending := str(state.get("pending_scene_path"))
		if not pending.is_empty():
			target = pending
		state.set("pending_scene_path", "")

	var error := tree.change_scene_to_file(target)
	if error != OK:
		push_warning("SceneTransitionBridge failed to load: %s (error %d)" % [target, error])
		if target != fallback_scene_path:
			tree.change_scene_to_file(fallback_scene_path)
