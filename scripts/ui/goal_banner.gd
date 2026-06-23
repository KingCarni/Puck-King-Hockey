extends Control

# Big, loud GOAL banner.
# Centered on screen, punch-in / hold / punch-out. Arcade lightning-bolt
# styling instead of broadcast graphics. No skulls — just chunky chrome.

const PUNCH_IN_TIME: float = 0.18
const PUNCH_OUT_TIME: float = 0.34
const HOLD_TIME: float = 2.48
const SETTLE_TIME: float = 0.12

const BANNER_WIDTH: float = 1640.0
const BANNER_HEIGHT: float = 380.0

signal banner_finished

var _palette: Node = null
var _backdrop_panel: PanelContainer = null
var _backdrop_style: StyleBoxFlat = null
var _stripe_top: ColorRect = null
var _stripe_bottom: ColorRect = null
var _diag_left: ColorRect = null
var _diag_right: ColorRect = null
var _main_label: Label = null
var _sub_label: Label = null
var _left_bolt: Label = null
var _right_bolt: Label = null
var _tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palette = get_node_or_null("/root/UiPalette")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	hide()

func _build_ui() -> void:
	# Single PanelContainer anchored to viewport center with explicit width/height.
	_backdrop_panel = PanelContainer.new()
	_backdrop_panel.name = "BannerPanel"
	_backdrop_panel.anchor_left = 0.5
	_backdrop_panel.anchor_right = 0.5
	_backdrop_panel.anchor_top = 0.5
	_backdrop_panel.anchor_bottom = 0.5
	_backdrop_panel.offset_left = -BANNER_WIDTH * 0.5
	_backdrop_panel.offset_right = BANNER_WIDTH * 0.5
	_backdrop_panel.offset_top = -BANNER_HEIGHT * 0.5
	_backdrop_panel.offset_bottom = BANNER_HEIGHT * 0.5
	_backdrop_panel.custom_minimum_size = Vector2(BANNER_WIDTH, BANNER_HEIGHT)
	_backdrop_panel.pivot_offset = Vector2(BANNER_WIDTH * 0.5, BANNER_HEIGHT * 0.5)
	_backdrop_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop_panel)

	_backdrop_style = StyleBoxFlat.new()
	_backdrop_style.bg_color = Color(0.10, 0.04, 0.05, 0.96)
	_backdrop_style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	_backdrop_style.set_border_width_all(8)
	_backdrop_style.set_corner_radius_all(14)
	_backdrop_style.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	_backdrop_style.shadow_size = 28
	_backdrop_style.content_margin_left = 24
	_backdrop_style.content_margin_right = 24
	_backdrop_style.content_margin_top = 24
	_backdrop_style.content_margin_bottom = 24
	_backdrop_panel.add_theme_stylebox_override("panel", _backdrop_style)

	# Diagonal accent stripes behind text.
	_diag_left = ColorRect.new()
	_diag_left.name = "DiagLeft"
	_diag_left.color = Color(1.0, 0.20, 0.22, 0.45)
	_diag_left.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_diag_left.offset_left = 60.0
	_diag_left.offset_top = 50.0
	_diag_left.offset_right = -BANNER_WIDTH * 0.5 - 100.0
	_diag_left.offset_bottom = -50.0
	_diag_left.rotation = deg_to_rad(-8.0)
	_diag_left.pivot_offset = Vector2(60.0, BANNER_HEIGHT * 0.5)
	_diag_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_panel.add_child(_diag_left)

	_diag_right = ColorRect.new()
	_diag_right.name = "DiagRight"
	_diag_right.color = Color(1.0, 0.20, 0.22, 0.45)
	_diag_right.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_diag_right.offset_left = BANNER_WIDTH * 0.5 + 100.0
	_diag_right.offset_top = 50.0
	_diag_right.offset_right = -60.0
	_diag_right.offset_bottom = -50.0
	_diag_right.rotation = deg_to_rad(-8.0)
	_diag_right.pivot_offset = Vector2(BANNER_WIDTH - 60.0, BANNER_HEIGHT * 0.5)
	_diag_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_panel.add_child(_diag_right)

	# Horizontal accent stripes at top and bottom.
	_stripe_top = ColorRect.new()
	_stripe_top.name = "StripeTop"
	_stripe_top.color = Color(1.0, 0.78, 0.10, 1.0)
	_stripe_top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_stripe_top.offset_top = -2.0
	_stripe_top.offset_bottom = 14.0
	_stripe_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_panel.add_child(_stripe_top)

	_stripe_bottom = ColorRect.new()
	_stripe_bottom.name = "StripeBottom"
	_stripe_bottom.color = Color(1.0, 0.78, 0.10, 1.0)
	_stripe_bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_stripe_bottom.offset_top = -14.0
	_stripe_bottom.offset_bottom = 2.0
	_stripe_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_panel.add_child(_stripe_bottom)

	# Layout row inside the banner: [bolt] [text column] [bolt]
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "BannerRow"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 36)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop_panel.add_child(row)

	_left_bolt = Label.new()
	_left_bolt.name = "LeftBolt"
	_left_bolt.text = "\u26A1"  # lightning bolt glyph
	_left_bolt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_left_bolt)

	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.name = "TextColumn"
	text_col.alignment = BoxContainer.ALIGNMENT_CENTER
	text_col.add_theme_constant_override("separation", 4)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_col)

	_main_label = Label.new()
	_main_label.name = "MainLabel"
	_main_label.text = "GOAL!"
	_main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_col.add_child(_main_label)

	_sub_label = Label.new()
	_sub_label.name = "SubLabel"
	_sub_label.text = "HOME SCORES"
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_col.add_child(_sub_label)

	_right_bolt = Label.new()
	_right_bolt.name = "RightBolt"
	_right_bolt.text = "\u26A1"
	_right_bolt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_right_bolt)

	if _palette != null:
		_palette.style_display_label(_main_label, 200, _palette.COLOR_HOT_GOLD)
		_palette.style_accent_label(_sub_label, 52, _palette.COLOR_BONE)
		_palette.style_display_label(_left_bolt, 220, _palette.COLOR_HOT_GOLD)
		_palette.style_display_label(_right_bolt, 220, _palette.COLOR_HOT_GOLD)

func celebrate(team: String) -> void:
	if _main_label == null:
		return

	var is_home: bool = team.to_upper() == "HOME"
	var accent: Color = Color(0.18, 0.55, 1.0, 1.0) if is_home else Color(1.0, 0.20, 0.22, 1.0)
	var sub_text: String = "HOME SCORES!" if is_home else "AWAY SCORES!"

	if _palette != null:
		accent = _palette.COLOR_HOME_BLUE if is_home else _palette.COLOR_AWAY_RED

	_main_label.text = "GOAL!"
	_sub_label.text = sub_text

	if _stripe_top != null:
		_stripe_top.color = accent
	if _stripe_bottom != null:
		_stripe_bottom.color = accent
	if _diag_left != null:
		_diag_left.color = Color(accent.r, accent.g, accent.b, 0.45)
	if _diag_right != null:
		_diag_right.color = Color(accent.r, accent.g, accent.b, 0.45)
	if _backdrop_style != null:
		var bg: Color = Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.18, 0.96)
		_backdrop_style.bg_color = bg

	if _tween != null and _tween.is_valid():
		_tween.kill()

	show()
	_backdrop_panel.scale = Vector2(1.55, 1.55)
	_backdrop_panel.rotation = deg_to_rad(-4.5)
	modulate.a = 0.0

	_tween = create_tween()
	# Punch in.
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, PUNCH_IN_TIME * 0.6)
	_tween.tween_property(_backdrop_panel, "scale", Vector2(1.0, 1.0), PUNCH_IN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_backdrop_panel, "rotation", 0.0, PUNCH_IN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(false)
	# Tiny settle wobble.
	_tween.tween_property(_backdrop_panel, "scale", Vector2(1.05, 1.05), SETTLE_TIME).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_backdrop_panel, "scale", Vector2(1.0, 1.0), SETTLE_TIME).set_trans(Tween.TRANS_SINE)
	# Hold.
	_tween.tween_interval(HOLD_TIME)
	# Punch out.
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, PUNCH_OUT_TIME)
	_tween.tween_property(_backdrop_panel, "scale", Vector2(1.35, 0.3), PUNCH_OUT_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.set_parallel(false)
	_tween.tween_callback(Callable(self, "_on_celebration_finished"))

func _on_celebration_finished() -> void:
	hide()
	emit_signal("banner_finished")
