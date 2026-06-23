extends Control

# Big, loud GOAL banner.
# Punch-in, brief hold, punch-out. Used for HOME and AWAY goals.

const PUNCH_IN_TIME: float = 0.18
const PUNCH_OUT_TIME: float = 0.34
const HOLD_TIME: float = 2.48
const SETTLE_TIME: float = 0.12

signal banner_finished

var _palette: Node = null
var _backdrop: ColorRect = null
var _stripe_top: ColorRect = null
var _stripe_bottom: ColorRect = null
var _shake_root: Control = null
var _content: Control = null
var _main_label: Label = null
var _sub_label: Label = null
var _tween: Tween = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palette = get_node_or_null("/root/UiPalette")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	hide()

func _build_ui() -> void:
	# Backdrop strip in the middle of the screen.
	_shake_root = Control.new()
	_shake_root.name = "ShakeRoot"
	_shake_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shake_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shake_root)

	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.color = Color(0.05, 0.05, 0.06, 0.92)
	_backdrop.anchor_left = 0.0
	_backdrop.anchor_right = 1.0
	_backdrop.anchor_top = 0.5
	_backdrop.anchor_bottom = 0.5
	_backdrop.offset_top = -210.0
	_backdrop.offset_bottom = 210.0
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shake_root.add_child(_backdrop)

	_stripe_top = ColorRect.new()
	_stripe_top.name = "StripeTop"
	_stripe_top.color = Color(1.0, 0.78, 0.10, 1.0)
	_stripe_top.anchor_left = 0.0
	_stripe_top.anchor_right = 1.0
	_stripe_top.anchor_top = 0.5
	_stripe_top.anchor_bottom = 0.5
	_stripe_top.offset_top = -222.0
	_stripe_top.offset_bottom = -210.0
	_stripe_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shake_root.add_child(_stripe_top)

	_stripe_bottom = ColorRect.new()
	_stripe_bottom.name = "StripeBottom"
	_stripe_bottom.color = Color(1.0, 0.78, 0.10, 1.0)
	_stripe_bottom.anchor_left = 0.0
	_stripe_bottom.anchor_right = 1.0
	_stripe_bottom.anchor_top = 0.5
	_stripe_bottom.anchor_bottom = 0.5
	_stripe_bottom.offset_top = 210.0
	_stripe_bottom.offset_bottom = 222.0
	_stripe_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shake_root.add_child(_stripe_bottom)

	# Content (will be scaled for punch-in / punch-out).
	_content = Control.new()
	_content.name = "Content"
	_content.anchor_left = 0.5
	_content.anchor_right = 0.5
	_content.anchor_top = 0.5
	_content.anchor_bottom = 0.5
	_content.pivot_offset = Vector2.ZERO
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shake_root.add_child(_content)

	_main_label = Label.new()
	_main_label.name = "MainLabel"
	_main_label.text = "GOAL!"
	_main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_main_label.anchor_left = 0.5
	_main_label.anchor_right = 0.5
	_main_label.anchor_top = 0.5
	_main_label.anchor_bottom = 0.5
	_main_label.offset_left = -700.0
	_main_label.offset_right = 700.0
	_main_label.offset_top = -150.0
	_main_label.offset_bottom = 30.0
	_main_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_main_label)

	_sub_label = Label.new()
	_sub_label.name = "SubLabel"
	_sub_label.text = "HOME SCORES"
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sub_label.anchor_left = 0.5
	_sub_label.anchor_right = 0.5
	_sub_label.anchor_top = 0.5
	_sub_label.anchor_bottom = 0.5
	_sub_label.offset_left = -700.0
	_sub_label.offset_right = 700.0
	_sub_label.offset_top = 40.0
	_sub_label.offset_bottom = 130.0
	_sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_sub_label)

	if _palette != null:
		_palette.style_display_label(_main_label, 220, _palette.COLOR_HOT_GOLD)
		_palette.style_accent_label(_sub_label, 56, _palette.COLOR_BONE)

func celebrate(team: String) -> void:
	if _main_label == null:
		return

	var is_home: bool = team.to_upper() == "HOME"
	var accent: Color = Color(0.18, 0.55, 1.0, 1.0) if is_home else Color(1.0, 0.20, 0.22, 1.0)
	var sub_text: String = "HOME SCORES" if is_home else "AWAY SCORES"

	if _palette != null:
		accent = _palette.COLOR_HOME_BLUE if is_home else _palette.COLOR_AWAY_RED

	_main_label.text = "GOAL!"
	_sub_label.text = sub_text

	# Tint stripes and backdrop border feel.
	if _stripe_top != null:
		_stripe_top.color = accent
	if _stripe_bottom != null:
		_stripe_bottom.color = accent
	if _backdrop != null:
		_backdrop.color = Color(accent.r * 0.18, accent.g * 0.18, accent.b * 0.18, 0.94)

	if _palette != null:
		_main_label.add_theme_color_override("font_color", _palette.COLOR_HOT_GOLD)

	if _tween != null and _tween.is_valid():
		_tween.kill()

	show()
	_content.scale = Vector2(1.55, 1.55)
	_content.rotation = deg_to_rad(-4.5)
	modulate.a = 0.0
	_shake_root.position = Vector2.ZERO

	_tween = create_tween()
	# Punch in.
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, PUNCH_IN_TIME * 0.6)
	_tween.tween_property(_content, "scale", Vector2(1.0, 1.0), PUNCH_IN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_content, "rotation", 0.0, PUNCH_IN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(false)
	# Tiny settle wobble.
	_tween.tween_property(_content, "scale", Vector2(1.06, 1.06), SETTLE_TIME).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_content, "scale", Vector2(1.0, 1.0), SETTLE_TIME).set_trans(Tween.TRANS_SINE)
	# Hold.
	_tween.tween_interval(HOLD_TIME)
	# Punch out.
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, PUNCH_OUT_TIME)
	_tween.tween_property(_content, "scale", Vector2(1.35, 0.3), PUNCH_OUT_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.set_parallel(false)
	_tween.tween_callback(Callable(self, "_on_celebration_finished"))

func _on_celebration_finished() -> void:
	hide()
	emit_signal("banner_finished")
