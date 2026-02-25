extends Control

func _game_state() -> Node:
	return get_node("/root/GameState")

func _format_city_details(city_name: String) -> String:
	var data: Dictionary = _game_state().get_city_data(city_name)
	var display_name: String = str(data.get("display_name", city_name))
	var description: String = str(data.get("description", ""))
	var latitude: float = float(data.get("latitude", 0.0))
	var longitude: float = float(data.get("longitude", 0.0))
	var altitude: float = float(data.get("altitude", 0.0))
	var map_key: String = _game_state().get_map_key_for_city(city_name)
	var high_score: int = int(_game_state().get_high_score(map_key))
	return "%s\n%s\nLat %.4f  Lon %.4f  Alt %.0fm\nBest Score: %d" % [display_name, description, latitude, longitude, altitude, high_score]

func _update_city_details(city_name: String) -> void:
	var details_label: Label = $CenterContainer/VBoxContainer/CityDetailsLabel
	details_label.text = _format_city_details(city_name)

func _ready() -> void:
	var city_option: OptionButton = $CenterContainer/VBoxContainer/CityOptionButton
	var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
	var back_button: Button = $CenterContainer/VBoxContainer/BackButton
	city_option.clear()
	for city_name in _game_state().get_city_names():
		city_option.add_item(city_name)

	if city_option.item_count > 0:
		var selected_index := 0
		var target_name: String = str(_game_state().selected_city_name)
		for i in range(city_option.item_count):
			if city_option.get_item_text(i) == target_name:
				selected_index = i
				break
		city_option.select(selected_index)
		var selected_name := city_option.get_item_text(selected_index)
		_game_state().set_selected_city(selected_name)
		_update_city_details(selected_name)

	city_option.item_selected.connect(_on_city_selected)
	play_button.pressed.connect(_on_play_pressed)
	back_button.pressed.connect(_on_back_pressed)
	city_option.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_city_selected(index: int) -> void:
	var city_option: OptionButton = $CenterContainer/VBoxContainer/CityOptionButton
	var selected_name := city_option.get_item_text(index)
	_game_state().set_selected_city(selected_name)
	_update_city_details(selected_name)

func _on_play_pressed() -> void:
	_game_state().show_world_loading_overlay = true
	get_tree().change_scene_to_file(_game_state().WORLD_SCENE_PATH)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
