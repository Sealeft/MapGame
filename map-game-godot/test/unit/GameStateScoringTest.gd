extends GdUnitTestSuite

var _game_state: Node

func before_test() -> void:
	_game_state = auto_free(load("res://scripts/GameState.gd").new())
	_game_state.high_scores_by_map = {}

func test_get_map_key_for_city_uses_city_prefix() -> void:
	assert_that(_game_state.get_map_key_for_city("Rome")).is_equal("city:Rome")
	assert_that(_game_state.get_map_key_for_city("New York")).is_equal("city:New York")

func test_submit_score_rejects_lower_or_equal_values() -> void:
	var key := "city:Tokyo"
	assert_bool(_game_state.submit_score(250, key)).is_true()
	assert_int(_game_state.get_high_score(key)).is_equal(250)

	assert_bool(_game_state.submit_score(250, key)).is_false()
	assert_bool(_game_state.submit_score(240, key)).is_false()
	assert_int(_game_state.get_high_score(key)).is_equal(250)

func test_submit_score_without_key_uses_selected_city() -> void:
	_game_state.set_selected_city("London")
	assert_bool(_game_state.submit_score(300)).is_true()
	assert_int(_game_state.get_high_score("city:London")).is_equal(300)
	assert_int(_game_state.get_high_score()).is_equal(300)

func test_get_selected_city_data_matches_selected_city() -> void:
	_game_state.set_selected_city("Paris")
	var data: Dictionary = _game_state.get_selected_city_data()
	assert_that(str(data.get("display_name", ""))).is_equal("Paris, France")
	assert_float(float(data.get("longitude", 0.0))).is_equal(2.3522)
