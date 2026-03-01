extends GdUnitTestSuite

func test_main_menu_scene_instantiates_with_core_buttons() -> void:
	var scene: PackedScene = load("res://main_menu.tscn")
	assert_that(scene).is_not_null()

	var instance: Node = auto_free(scene.instantiate())
	assert_that(instance).is_not_null()
	assert_that(instance.has_node("CenterContainer/VBoxContainer/PlayButton")).is_true()
	assert_that(instance.has_node("CenterContainer/VBoxContainer/ControlsButton")).is_true()
	assert_that(instance.has_node("CenterContainer/VBoxContainer/ExitButton")).is_true()

func test_city_select_scene_instantiates_with_city_controls() -> void:
	var scene: PackedScene = load("res://city_select.tscn")
	assert_that(scene).is_not_null()

	var instance: Node = auto_free(scene.instantiate())
	assert_that(instance).is_not_null()
	assert_that(instance.has_node("CenterContainer/VBoxContainer/CityOptionButton")).is_true()
	assert_that(instance.has_node("CenterContainer/VBoxContainer/PlayButton")).is_true()
	assert_that(instance.has_node("CenterContainer/VBoxContainer/BackButton")).is_true()

func test_objective_hud_scene_has_required_runtime_nodes() -> void:
	var scene: PackedScene = load("res://ui/objective_hud.tscn")
	assert_that(scene).is_not_null()

	var hud: Node = auto_free(scene.instantiate())
	assert_that(hud).is_not_null()
	assert_that(hud.has_node("HudPanel/HudInfoContainer/TimeLabel")).is_true()
	assert_that(hud.has_node("HudPanel/HudInfoContainer/ScoreLabel")).is_true()
	assert_that(hud.has_node("GameOverPanel")).is_true()
	assert_that(hud.has_node("PausePanel")).is_true()
