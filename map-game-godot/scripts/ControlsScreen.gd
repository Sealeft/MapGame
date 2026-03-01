extends Control

var _title_anim_time: float = 0.0
var _title_base_position: Vector2 = Vector2.ZERO
const _TITLE_PALETTE: Array[Color] = [
	Color("#41431B"),
	Color("#AEB784"),
	Color("#E3DBBB"),
	Color("#F8F3E1")
]
@onready var _title_label: Label = $CenterContainer/VBoxContainer/TitleLabel

func _ready() -> void:
	if _title_label != null:
		_title_base_position = _title_label.position
	set_process(true)
	$CenterContainer/VBoxContainer/BackButton.grab_focus()

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

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
