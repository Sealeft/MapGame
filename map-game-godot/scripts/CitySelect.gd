extends Control

var _title_anim_time: float = 0.0
var _title_base_position: Vector2 = Vector2.ZERO
const _COLOR_DARK := Color("#41431B")
const _COLOR_MID := Color("#AEB784")
const _COLOR_LIGHT := Color("#E3DBBB")
const _COLOR_CREAM := Color("#F8F3E1")
const _TITLE_PALETTE: Array[Color] = [
	_COLOR_DARK,
	_COLOR_MID,
	_COLOR_LIGHT,
	_COLOR_CREAM
]
@onready var _title_label: Label = $CenterContainer/VBoxContainer/TitleLabel

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
	if _title_label != null:
		_title_base_position = _title_label.position
	set_process(true)
	_apply_dropdown_palette(city_option)

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

	city_option.grab_focus()

func _apply_dropdown_palette(city_option: OptionButton) -> void:
	if city_option == null:
		return

	city_option.add_theme_color_override("font_color", _COLOR_DARK)
	city_option.add_theme_color_override("font_focus_color", _COLOR_DARK)
	city_option.add_theme_color_override("font_hover_color", _COLOR_DARK)

	var popup := city_option.get_popup()
	if popup == null:
		return

	popup.add_theme_color_override("font_color", _COLOR_CREAM)
	popup.add_theme_color_override("font_hover_color", _COLOR_CREAM)
	popup.add_theme_color_override("font_selected_color", _COLOR_DARK)
	popup.add_theme_color_override("font_separator_color", _COLOR_LIGHT)

	var popup_panel := StyleBoxFlat.new()
	popup_panel.bg_color = _COLOR_DARK
	popup_panel.border_width_left = 1
	popup_panel.border_width_top = 1
	popup_panel.border_width_right = 1
	popup_panel.border_width_bottom = 1
	popup_panel.border_color = _COLOR_LIGHT
	popup_panel.corner_radius_top_left = 8
	popup_panel.corner_radius_top_right = 8
	popup_panel.corner_radius_bottom_right = 8
	popup_panel.corner_radius_bottom_left = 8
	popup.add_theme_stylebox_override("panel", popup_panel)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(_COLOR_MID, 0.95)
	hover_style.border_width_left = 1
	hover_style.border_width_top = 1
	hover_style.border_width_right = 1
	hover_style.border_width_bottom = 1
	hover_style.border_color = _COLOR_CREAM
	hover_style.corner_radius_top_left = 6
	hover_style.corner_radius_top_right = 6
	hover_style.corner_radius_bottom_right = 6
	hover_style.corner_radius_bottom_left = 6
	popup.add_theme_stylebox_override("hover", hover_style)

	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = _COLOR_LIGHT
	selected_style.border_width_left = 1
	selected_style.border_width_top = 1
	selected_style.border_width_right = 1
	selected_style.border_width_bottom = 1
	selected_style.border_color = _COLOR_CREAM
	selected_style.corner_radius_top_left = 6
	selected_style.corner_radius_top_right = 6
	selected_style.corner_radius_bottom_right = 6
	selected_style.corner_radius_bottom_left = 6
	popup.add_theme_stylebox_override("hover_mirrored", selected_style)

func _process(delta: float) -> void:
	if _title_label == null:
		return
	_title_anim_time += delta
	_title_label.rotation = sin(_title_anim_time * 1.35) * 0.02
	var scale_offset := sin(_title_anim_time * 1.8) * 0.018
	_title_label.scale = Vector2.ONE * (1.0 + scale_offset)
	_title_label.position = _title_base_position + Vector2(cos(_title_anim_time * 1.0) * 1.8, sin(_title_anim_time * 1.6) * 2.4)
	_title_label.modulate = _sample_title_palette(_title_anim_time * 0.65)

func _sample_title_palette(time_value: float) -> Color:
	if _TITLE_PALETTE.size() == 0:
		return Color.WHITE
	if _TITLE_PALETTE.size() == 1:
		return _TITLE_PALETTE[0]

	var length := float(_TITLE_PALETTE.size())
	var wrapped := fposmod(time_value, length)
	var index := int(floor(wrapped))
	var next_index := (index + 1) % _TITLE_PALETTE.size()
	var blend := wrapped - float(index)
	return _TITLE_PALETTE[index].lerp(_TITLE_PALETTE[next_index], blend)

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
