extends GdUnitTestSuite

var _game_state: Node

func before_test() -> void:
	_game_state = auto_free(load("res://scripts/GameState.gd").new())
	_game_state.high_scores_by_map = {}

func test_city_names_belfast_first_and_contains_expected_entries() -> void:
	var names: PackedStringArray = _game_state.get_city_names()
	assert_int(names.size()).is_greater_equal(4)
	assert_that(names[0]).is_equal("Belfast")
	assert_that(Array(names).has("Tokyo")).is_true()
	assert_that(Array(names).has("London")).is_true()

func test_set_selected_city_ignores_unknown_city() -> void:
	_game_state.set_selected_city("Paris")
	assert_that(_game_state.selected_city_name).is_equal("Paris")

	_game_state.set_selected_city("Unknown City")
	assert_that(_game_state.selected_city_name).is_equal("Paris")

func test_get_city_data_returns_fallback_for_unknown_city() -> void:
	var fallback_data: Dictionary = _game_state.get_city_data("ThisDoesNotExist")
	assert_that(str(fallback_data.get("display_name", ""))).is_equal("Belfast, UK")
	assert_that(float(fallback_data.get("latitude", 0.0))).is_equal(54.597)

func test_get_high_score_uses_selected_city_key() -> void:
	_game_state.set_selected_city("Rome")
	assert_int(_game_state.get_high_score()).is_equal(0)

	var map_key: String = _game_state.get_current_map_key()
	_game_state.high_scores_by_map[map_key] = 420
	assert_int(_game_state.get_high_score()).is_equal(420)
