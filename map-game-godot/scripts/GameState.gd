extends Node

const WORLD_SCENE_PATH := "res://node_3d.tscn"
const SAVE_FILE_PATH := "user://mapgame_save.json"

const CITIES := {
	"Belfast": {
		"display_name": "Belfast, UK",
		"description": "Coastal routes with mixed elevation and long sightlines.",
		"latitude": 54.5970,
		"longitude": -5.9300,
		"altitude": 100.0
	},
	"New York": {
		"display_name": "New York, USA",
		"description": "Dense urban layout with vertical movement opportunities.",
		"latitude": 40.7128,
		"longitude": -74.0060,
		"altitude": 120.0
	},
	"Tokyo": {
		"display_name": "Tokyo, Japan",
		"description": "Wide city sprawl with varied building heights.",
		"latitude": 35.6762,
		"longitude": 139.6503,
		"altitude": 120.0
	}
}

var selected_city_name: String = "Belfast"
var show_world_loading_overlay: bool = false
var world_loading_overlay_seconds: float = 5.0
var high_scores_by_map: Dictionary = {}

func _ready() -> void:
	_load_persistent_data()

func get_current_map_key() -> String:
	return get_map_key_for_city(selected_city_name)

func get_map_key_for_city(city_name: String) -> String:
	return "city:%s" % city_name

func get_high_score(map_key: String = "") -> int:
	var key := map_key if map_key != "" else get_current_map_key()
	if not high_scores_by_map.has(key):
		return 0
	return int(high_scores_by_map.get(key, 0))

func submit_score(score: int, map_key: String = "") -> bool:
	var key := map_key if map_key != "" else get_current_map_key()
	var current_best := get_high_score(key)
	if score <= current_best:
		return false
	high_scores_by_map[key] = score
	_save_persistent_data()
	return true

func _save_persistent_data() -> void:
	var payload := {
		"high_scores_by_map": high_scores_by_map
	}
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))

func _load_persistent_data() -> void:
	high_scores_by_map = {}
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		return
	var content := file.get_as_text()
	if content.is_empty():
		return
	var parsed: Variant = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	var scores_any = data.get("high_scores_by_map", {})
	if typeof(scores_any) == TYPE_DICTIONARY:
		high_scores_by_map = scores_any

func get_city_names() -> PackedStringArray:
	var names := PackedStringArray()
	for city_name in CITIES.keys():
		names.append(city_name)
	names.sort()
	if names.has("Belfast"):
		names.remove_at(names.find("Belfast"))
		names.insert(0, "Belfast")
	return names

func set_selected_city(city_name: String) -> void:
	if CITIES.has(city_name):
		selected_city_name = city_name

func get_city_data(city_name: String) -> Dictionary:
	if CITIES.has(city_name):
		return CITIES[city_name]
	return CITIES["Belfast"]

func get_selected_city_data() -> Dictionary:
	return get_city_data(selected_city_name)
