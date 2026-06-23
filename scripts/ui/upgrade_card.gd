extends Control

# Single upgrade card used by the reward draft.
# Big, controller-friendly. Hover/focus pops the card with a gold glow.

signal card_chosen(index: int)

@export var card_index: int = 0
@export var card_title: String = "UPGRADE"
@export var card_description: String = "Does cool stuff."
@export var hotkey_label: String = "1"
@export var controller_label: String = "A"

const HOVER_SCALE: Vector2 = Vector2(1.06, 1.06)
const REST_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_TIME: float = 0.12

var _palette: Node = null
var _panel: PanelContainer = null
var _ribbon: PanelContainer = null
var _ribbon_label: Label = null
var _title_label: Label = null
var _description_label: Label = null
var _hotkey_pill: PanelContainer = null
var _hotkey_label_node: Label = null
var _button: Button = null
var _hover_tween: Tween = null
var _is_focused: bool = false

func _ready() -> void:
	_palette = get_node_or_null("/root/UiPalette")
	custom_minimum_size = Vector2(420.0, 560.0)
	pivot_offset = Vector2(210.0, 280.0)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	_refresh_text()

func configure(index: int, title: String, description: String, hotkey: String = "", controller: String = "") -> void:
	card_index = index
	card_title = title
	card_description = description
	if hotkey != "":
		hotkey_label = hotkey
	if controller != "":
		controller_label = controller
	_refresh_text()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.07, 0.07, 0.085, 0.98)
	panel_style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	panel_style.set_border_width_all(5)
	panel_style.set_corner_radius_all(14)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	panel_style.shadow_size = 14
	panel_style.content_margin_left = 26
	panel_style.content_margin_right = 26
	panel_style.content_margin_top = 26
	panel_style.content_margin_bottom = 26
	_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "Content"
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 20)
	_panel.add_child(vbox)

	# Ribbon header (e.g. "PICK 1").
	_ribbon = PanelContainer.new()
	_ribbon.name = "Ribbon"
	_ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var ribbon_style: StyleBoxFlat = StyleBoxFlat.new()
	ribbon_style.bg_color = Color(0.85, 0.10, 0.13, 1.0)
	ribbon_style.border_color = Color(1.0, 0.92, 0.30, 1.0)
	ribbon_style.set_border_width_all(3)
	ribbon_style.set_corner_radius_all(6)
	ribbon_style.content_margin_left = 22
	ribbon_style.content_margin_right = 22
	ribbon_style.content_margin_top = 8
	ribbon_style.content_margin_bottom = 8
	_ribbon.add_theme_stylebox_override("panel", ribbon_style)
	vbox.add_child(_ribbon)

	_ribbon_label = Label.new()
	_ribbon_label.name = "RibbonLabel"
	_ribbon_label.text = "PICK"
	_ribbon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ribbon.add_child(_ribbon_label)

	# Big icon-shaped panel placeholder.
	var icon_panel: PanelContainer = PanelContainer.new()
	icon_panel.name = "IconArea"
	icon_panel.custom_minimum_size = Vector2(0.0, 150.0)
	icon_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon_style: StyleBoxFlat = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.12, 0.12, 0.14, 1.0)
	icon_style.border_color = Color(0.55, 0.58, 0.62, 1.0)
	icon_style.set_border_width_all(2)
	icon_style.set_corner_radius_all(8)
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	vbox.add_child(icon_panel)

	var icon_label: Label = Label.new()
	icon_label.name = "IconGlyph"
	icon_label.text = "★"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_panel.add_child(icon_label)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_title_label)

	_description_label = Label.new()
	_description_label.name = "Description"
	_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_description_label)

	# Hotkey pill ("1 / A").
	_hotkey_pill = PanelContainer.new()
	_hotkey_pill.name = "HotkeyPill"
	_hotkey_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = Color(0.05, 0.05, 0.06, 1.0)
	pill_style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	pill_style.set_border_width_all(3)
	pill_style.set_corner_radius_all(22)
	pill_style.content_margin_left = 26
	pill_style.content_margin_right = 26
	pill_style.content_margin_top = 8
	pill_style.content_margin_bottom = 8
	_hotkey_pill.add_theme_stylebox_override("panel", pill_style)
	vbox.add_child(_hotkey_pill)

	_hotkey_label_node = Label.new()
	_hotkey_label_node.name = "HotkeyText"
	_hotkey_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hotkey_pill.add_child(_hotkey_label_node)

	# Invisible full-card button for mouse + keyboard focus.
	_button = Button.new()
	_button.name = "ClickArea"
	_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_button.flat = true
	_button.focus_mode = Control.FOCUS_ALL
	_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_button.pressed.connect(_on_pressed)
	_button.mouse_entered.connect(_on_hover_start)
	_button.mouse_exited.connect(_on_hover_end)
	_button.focus_entered.connect(_on_hover_start)
	_button.focus_exited.connect(_on_hover_end)
	add_child(_button)

	# Style font sizes via palette if available.
	if _palette != null:
		_palette.style_accent_label(_ribbon_label, 28, _palette.COLOR_BONE)
		_palette.style_display_label(_title_label, 40, _palette.COLOR_HOT_GOLD)
		_palette.style_display_label(_description_label, 22, _palette.COLOR_BONE)
		_palette.style_accent_label(_hotkey_label_node, 26, _palette.COLOR_GOLD)
		_palette.style_display_label(icon_label, 110, _palette.COLOR_GOLD)

func _refresh_text() -> void:
	if _ribbon_label != null:
		_ribbon_label.text = "PICK %d" % (card_index + 1)
	if _title_label != null:
		_title_label.text = card_title.to_upper()
	if _description_label != null:
		_description_label.text = card_description
	if _hotkey_label_node != null:
		_hotkey_label_node.text = "%s / %s" % [hotkey_label, controller_label]

func grab_card_focus() -> void:
	if _button != null:
		_button.grab_focus()

func _on_pressed() -> void:
	emit_signal("card_chosen", card_index)

func _on_hover_start() -> void:
	_is_focused = true
	_animate_scale(HOVER_SCALE)
	_set_border_color(Color(1.0, 0.92, 0.30, 1.0), 7)

func _on_hover_end() -> void:
	_is_focused = false
	_animate_scale(REST_SCALE)
	_set_border_color(Color(1.0, 0.78, 0.10, 1.0), 5)

func _animate_scale(target_scale: Vector2) -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", target_scale, HOVER_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_border_color(color: Color, width: int) -> void:
	if _panel == null:
		return
	var style: StyleBoxFlat = _panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style.border_color = color
	style.set_border_width_all(width)
