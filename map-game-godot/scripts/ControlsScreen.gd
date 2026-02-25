extends Control

func _ready() -> void:
	$CenterContainer/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	$CenterContainer/VBoxContainer/BackButton.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
