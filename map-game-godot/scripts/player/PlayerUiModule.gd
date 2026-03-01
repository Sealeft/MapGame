class_name PlayerUiModule
extends RefCounted

static func bind_debug_ui(host: Node, show_debug_text: bool, debug_font_size: int) -> Dictionary:
	var debug_layer := host.get_node_or_null("PlayerDebugLayer") as CanvasLayer
	var debug_label := host.get_node_or_null("PlayerDebugLayer/MovementDebugLabel") as Label
	if debug_layer:
		debug_layer.visible = show_debug_text
	if debug_label:
		debug_label.add_theme_font_size_override("font_size", debug_font_size)

	return {
		"debug_layer": debug_layer,
		"debug_label": debug_label
	}

static func bind_grapple_crosshair_ui(host: Node, grapple_crosshair_size: float, grapple_crosshair_thickness: float, grapple_crosshair_gap: float, grapple_crosshair_color_invalid: Color, grapple_crosshair_color_valid: Color) -> Dictionary:
	var grapple_crosshair_layer := host.get_node_or_null("GrappleCrosshairLayer") as CanvasLayer
	var grapple_crosshair_center := host.get_node_or_null("GrappleCrosshairLayer/GrappleCrosshair") as Control
	var grapple_crosshair_h := host.get_node_or_null("GrappleCrosshairLayer/GrappleCrosshair/CrosshairH") as ColorRect
	var grapple_crosshair_v := host.get_node_or_null("GrappleCrosshairLayer/GrappleCrosshair/CrosshairV") as ColorRect
	var grapple_indicator_root := host.get_node_or_null("GrappleCrosshairLayer/GrappleCrosshair/GrappleCooldownIndicator") as Control
	var grapple_indicator_icon := host.get_node_or_null("GrappleCrosshairLayer/GrappleCrosshair/GrappleCooldownIndicator/GrappleIcon") as Label
	var grapple_indicator_bar_bg := host.get_node_or_null("GrappleCrosshairLayer/GrappleCrosshair/GrappleCooldownIndicator/CooldownBarBg") as ColorRect
	var grapple_indicator_bar_fill := host.get_node_or_null("GrappleCrosshairLayer/GrappleCrosshair/GrappleCooldownIndicator/CooldownBarBg/CooldownBarFill") as ColorRect

	if grapple_crosshair_center:
		grapple_crosshair_center.offset_left = -grapple_crosshair_size * 0.5
		grapple_crosshair_center.offset_top = -grapple_crosshair_size * 0.5
		grapple_crosshair_center.offset_right = grapple_crosshair_size * 0.5
		grapple_crosshair_center.offset_bottom = grapple_crosshair_size * 0.5

	if grapple_crosshair_h:
		grapple_crosshair_h.color = grapple_crosshair_color_invalid
		grapple_crosshair_h.size = Vector2(grapple_crosshair_size, grapple_crosshair_thickness)
		grapple_crosshair_h.position = Vector2(0.0, (grapple_crosshair_size - grapple_crosshair_thickness) * 0.5)

	if grapple_crosshair_v:
		grapple_crosshair_v.color = grapple_crosshair_color_invalid
		grapple_crosshair_v.size = Vector2(grapple_crosshair_thickness, grapple_crosshair_size)
		grapple_crosshair_v.position = Vector2((grapple_crosshair_size - grapple_crosshair_thickness) * 0.5, 0.0)

	if grapple_crosshair_h and grapple_crosshair_v and grapple_crosshair_gap > 0.0:
		var half_gap := grapple_crosshair_gap * 0.5
		grapple_crosshair_h.size.x = maxf(grapple_crosshair_size - grapple_crosshair_gap, 1.0)
		grapple_crosshair_h.position.x = half_gap
		grapple_crosshair_v.size.y = maxf(grapple_crosshair_size - grapple_crosshair_gap, 1.0)
		grapple_crosshair_v.position.y = half_gap

	if grapple_indicator_root:
		grapple_indicator_root.position = Vector2(-8.0, grapple_crosshair_size + 10.0)
		grapple_indicator_root.custom_minimum_size = Vector2(56.0, 12.0)

	if grapple_indicator_icon:
		grapple_indicator_icon.add_theme_font_size_override("font_size", 12)
		grapple_indicator_icon.text = "⛓"

	if grapple_indicator_bar_bg:
		grapple_indicator_bar_bg.color = Color(0.06, 0.08, 0.1, 0.7)
	if grapple_indicator_bar_fill:
		grapple_indicator_bar_fill.color = grapple_crosshair_color_valid

	return {
		"grapple_crosshair_layer": grapple_crosshair_layer,
		"grapple_crosshair_center": grapple_crosshair_center,
		"grapple_crosshair_h": grapple_crosshair_h,
		"grapple_crosshair_v": grapple_crosshair_v,
		"grapple_indicator_root": grapple_indicator_root,
		"grapple_indicator_icon": grapple_indicator_icon,
		"grapple_indicator_bar_fill": grapple_indicator_bar_fill
	}

static func set_grapple_indicator(grapple_indicator_icon: Label, grapple_indicator_bar_fill: ColorRect, color: Color, fill_ratio: float) -> void:
	if grapple_indicator_icon:
		grapple_indicator_icon.modulate = color
	if grapple_indicator_bar_fill:
		grapple_indicator_bar_fill.color = color
		var ratio := clampf(fill_ratio, 0.0, 1.0)
		grapple_indicator_bar_fill.size.x = 40.0 * ratio

static func set_crosshair_color(grapple_crosshair_h: ColorRect, grapple_crosshair_v: ColorRect, color: Color) -> void:
	if grapple_crosshair_h:
		grapple_crosshair_h.color = color
	if grapple_crosshair_v:
		grapple_crosshair_v.color = color
