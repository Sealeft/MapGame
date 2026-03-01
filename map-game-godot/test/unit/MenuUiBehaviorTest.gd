extends GdUnitTestSuite

func test_main_menu_sample_title_palette_starts_with_theme_dark() -> void:
	var menu: Control = auto_free(load("res://scripts/MainMenu.gd").new())
	var color: Color = menu._sample_title_palette(0.0)
	assert_float(color.r).is_equal(Color("#41431B").r)
	assert_float(color.g).is_equal(Color("#41431B").g)
	assert_float(color.b).is_equal(Color("#41431B").b)

func test_controls_screen_sample_title_palette_wraps() -> void:
	var controls: Control = auto_free(load("res://scripts/ControlsScreen.gd").new())
	var color_a: Color = controls._sample_title_palette(0.0)
	var color_b: Color = controls._sample_title_palette(4.0)
	assert_float(color_a.r).is_equal(color_b.r)
	assert_float(color_a.g).is_equal(color_b.g)
	assert_float(color_a.b).is_equal(color_b.b)

func test_city_select_apply_dropdown_palette_sets_overrides() -> void:
	var city_select: Control = auto_free(load("res://scripts/CitySelect.gd").new())
	var option_button: OptionButton = auto_free(OptionButton.new())

	city_select._apply_dropdown_palette(option_button)

	assert_bool(option_button.has_theme_color_override("font_color")).is_true()
	assert_bool(option_button.has_theme_color_override("font_focus_color")).is_true()
	assert_bool(option_button.has_theme_color_override("font_hover_color")).is_true()

	var popup := option_button.get_popup()
	assert_that(popup).is_not_null()
	assert_bool(popup.has_theme_color_override("font_color")).is_true()
	assert_bool(popup.has_theme_stylebox_override("panel")).is_true()
	assert_bool(popup.has_theme_stylebox_override("hover")).is_true()
	assert_bool(popup.has_theme_stylebox_override("hover_mirrored")).is_true()

func test_city_select_apply_dropdown_palette_handles_null_safely() -> void:
	var city_select: Control = auto_free(load("res://scripts/CitySelect.gd").new())
	city_select._apply_dropdown_palette(null)
	assert_bool(true).is_true()
