extends Control

var _input_unlock_time_msec: int = 0
var _logo_anim_time: float = 0.0
@onready var _title_logo: RichTextLabel = $CenterContainer/VBoxContainer/TitleLabel

func _can_accept_menu_input() -> bool:
	return Time.get_ticks_msec() >= _input_unlock_time_msec

func _ready() -> void:
	_input_unlock_time_msec = Time.get_ticks_msec() + 250
	var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
	var controls_button: Button = $CenterContainer/VBoxContainer/ControlsButton
	var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton
	play_button.pressed.connect(_on_play_pressed)
	controls_button.pressed.connect(_on_controls_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	play_button.grab_focus()
	set_process(true)

func _process(delta: float) -> void:
	if _title_logo == null:
		return
	_logo_anim_time += delta
	_title_logo.rotation = sin(_logo_anim_time * 1.5) * 0.03
	var scale_offset := sin(_logo_anim_time * 2.0) * 0.02
	_title_logo.scale = Vector2.ONE * (1.0 + scale_offset)

func _unhandled_input(event: InputEvent) -> void:
	if not _can_accept_menu_input():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_exit_pressed()

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
