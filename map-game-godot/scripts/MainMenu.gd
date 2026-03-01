extends Control

var _input_unlock_time_msec: int = 0
var _logo_anim_time: float = 0.0
var _title_base_position: Vector2 = Vector2.ZERO
const _TITLE_PALETTE: Array[Color] = [
	Color("#41431B"),
	Color("#AEB784"),
	Color("#E3DBBB"),
	Color("#F8F3E1")
]
@onready var _title_logo: RichTextLabel = $CenterContainer/VBoxContainer/TitleLabel

func _can_accept_menu_input() -> bool:
	return Time.get_ticks_msec() >= _input_unlock_time_msec

func _ready() -> void:
	_input_unlock_time_msec = Time.get_ticks_msec() + 250
	$CenterContainer/VBoxContainer/PlayButton.grab_focus()
	if _title_logo != null:
		_title_base_position = _title_logo.position
	set_process(true)

func _process(delta: float) -> void:
	if _title_logo == null:
		return
	_logo_anim_time += delta
	_title_logo.rotation = sin(_logo_anim_time * 1.55) * 0.035
	var scale_offset := sin(_logo_anim_time * 2.1) * 0.028
	_title_logo.scale = Vector2.ONE * (1.0 + scale_offset)
	_title_logo.position = _title_base_position + Vector2(cos(_logo_anim_time * 1.2) * 2.5, sin(_logo_anim_time * 2.0) * 3.5)
	_title_logo.modulate = _sample_title_palette(_logo_anim_time * 0.75)

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
	if not _can_accept_menu_input():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		accept_event()

func _on_play_pressed() -> void:
	if not _can_accept_menu_input():
		return
	get_tree().change_scene_to_file("res://city_select.tscn")

func _on_controls_pressed() -> void:
	if not _can_accept_menu_input():
		return
	get_tree().change_scene_to_file("res://controls_screen.tscn")

func _on_exit_pressed() -> void:
	if not _can_accept_menu_input():
		return
	get_tree().quit()
