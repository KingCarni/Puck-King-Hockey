extends Control

# Reusable arcade notification banner.
# Slides in from the top, holds, then slides out. Used for status updates,
# upgrade pickups, and other transient messages.

const SLIDE_IN_TIME: float = 0.22
const SLIDE_OUT_TIME: float = 0.30
const DEFAULT_HOLD_TIME: float = 1.6

var _palette: Node = null
var _panel: PanelContainer = null
var _label: Label = null
var _tween: Tween = null
var _start_y: float = -200.0
var _resting_y: float = 24.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_palette = get_node_or_null("/root/UiPalette")
	_build_ui()
	hide()

func _build_ui() -> void:
	custom_minimum_size = Vector2(720.0, 0.0)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -360.0
	offset_right = 360.0
	offset_top = _start_y
	offset_bottom = _start_y + 110.0

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.06, 0.92)
	style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	_panel.add_theme_stylebox_override("panel", style)

	_label = Label.new()
	_label.name = "MessageLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_label)

	if _palette != null:
		_palette.style_display_label(_label, 34, _palette.COLOR_BONE)

func show_message(message: String, accent_color: Color = Color(1.0, 0.78, 0.10, 1.0), hold_time: float = DEFAULT_HOLD_TIME) -> void:
	if _label == null:
		return
	_label.text = message.to_upper()

	# Restyle border to accent color of this message.
	var style: StyleBoxFlat = _panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.border_color = accent_color

	if _tween != null and _tween.is_valid():
		_tween.kill()

	show()
	offset_top = _start_y
	offset_bottom = _start_y + 110.0
	modulate.a = 0.0

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "offset_top", _resting_y, SLIDE_IN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "offset_bottom", _resting_y + 110.0, SLIDE_IN_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, SLIDE_IN_TIME * 0.6)
	_tween.set_parallel(false)
	_tween.tween_interval(hold_time)
	_tween.set_parallel(true)
	_tween.tween_property(self, "offset_top", _start_y, SLIDE_OUT_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "offset_bottom", _start_y + 110.0, SLIDE_OUT_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, SLIDE_OUT_TIME)
	_tween.chain().tween_callback(Callable(self, "hide"))
