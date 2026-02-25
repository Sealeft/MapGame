extends Control

var _progress: Array = []
@export var post_load_wait_seconds: float = 5.0
var _pending_scene: PackedScene = null
var _post_load_timer: float = 0.0
var _is_waiting_after_load: bool = false

func _game_state() -> Node:
	return get_node("/root/GameState")

func _ready() -> void:
	$CenterContainer/VBoxContainer/StatusLabel.text = "Loading %s..." % _game_state().selected_city_name
	$CenterContainer/VBoxContainer/ProgressBar.value = 0.0
	ResourceLoader.load_threaded_request(_game_state().WORLD_SCENE_PATH)

func _process(delta: float) -> void:
	if _is_waiting_after_load:
		_post_load_timer += delta
		var wait_ratio := clampf(_post_load_timer / maxf(post_load_wait_seconds, 0.001), 0.0, 1.0)
		$CenterContainer/VBoxContainer/ProgressBar.value = 100.0
		$CenterContainer/VBoxContainer/StatusLabel.text = "Preparing spawn... %d%%" % int(wait_ratio * 100.0)
		if _post_load_timer >= post_load_wait_seconds:
			if _pending_scene != null:
				get_tree().change_scene_to_packed(_pending_scene)
		return

	var status := ResourceLoader.load_threaded_get_status(_game_state().WORLD_SCENE_PATH, _progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_pending_scene = ResourceLoader.load_threaded_get(_game_state().WORLD_SCENE_PATH)
		if _pending_scene != null:
			_is_waiting_after_load = true
			_post_load_timer = 0.0
			$CenterContainer/VBoxContainer/StatusLabel.text = "Preparing spawn..."
	elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if _progress.size() > 0:
			$CenterContainer/VBoxContainer/ProgressBar.value = float(_progress[0]) * 100.0
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		$CenterContainer/VBoxContainer/StatusLabel.text = "Failed to load city."
