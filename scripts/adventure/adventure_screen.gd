extends Control

# Base class for every Adventure Mode screen. Provides the shared frame:
#
#   ADVENTURE MODE          <context: tournament progress + currencies>
#   <SCREEN TITLE>
#   ─────────────────────────────────────────────
#   [ content built by the subclass ]
#   ─────────────────────────────────────────────
#   <footer input hints>
#
# Subclasses override:
#   _screen_title()  -> String        big heading
#   _footer_hints()  -> String        e.g. "A — SELECT      B — BACK"
#   _build_content(parent: Control)   screen body
#   _default_focus() -> Control       control focused on entry (or null)
#   _on_back() -> bool                default routes to AdventureFlow.back()
#
# Controller support: B / Esc / Start trigger back; buttons made through
# make_button() carry the UiPalette focus style, so focus is always visible.

const PlayerDefinitionScript = preload("res://scripts/roster/player_definition.gd")

const COLOR_GOLD: Color = Color(1.0, 0.78, 0.10, 1.0)
const COLOR_HOT_GOLD: Color = Color(1.0, 0.92, 0.30, 1.0)
const COLOR_BONE: Color = Color(0.97, 0.96, 0.92, 1.0)
const COLOR_STEEL: Color = Color(0.55, 0.58, 0.62, 1.0)
const COLOR_BLOOD_RED: Color = Color(0.85, 0.10, 0.13, 1.0)
const COLOR_HOME_BLUE: Color = Color(0.18, 0.55, 1.0, 1.0)
const COLOR_DARK_FILL: Color = Color(0.055, 0.055, 0.07, 0.94)
const COLOR_PANEL_FILL: Color = Color(0.028, 0.028, 0.042, 0.90)

var _flow: Node = null
var _palette: Node = null
var _content_root: MarginContainer = null
var _context_label: Label = null

func _ready() -> void:
	_flow = get_node_or_null("/root/AdventureFlow")
	_palette = get_node_or_null("/root/UiPalette")
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_frame()
	_build_content(_content_root)
	call_deferred("_grab_default_focus")

# ---------------------------------------------------------- overridables ---

func _screen_title() -> String:
	return "ADVENTURE"

func _footer_hints() -> String:
	return "A / ENTER — SELECT      B / ESC — BACK"

func _build_content(_parent: Control) -> void:
	pass

func _default_focus() -> Control:
	return null

## Return true when back input was consumed.
func _on_back() -> bool:
	if _flow != null:
		return bool(_flow.call("back"))
	return false

# ----------------------------------------------------------------- frame ---

func _build_frame() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.name = "Backdrop"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.016, 0.016, 0.024, 1.0)
	add_child(bg)

	var red_wash: ColorRect = ColorRect.new()
	red_wash.color = Color(0.45, 0.05, 0.07, 0.10)
	_anchor_box(red_wash, 0.0, 0.35, 0.0, 1.0)
	add_child(red_wash)

	var blue_wash: ColorRect = ColorRect.new()
	blue_wash.color = Color(0.05, 0.15, 0.45, 0.10)
	_anchor_box(blue_wash, 0.65, 1.0, 0.0, 1.0)
	add_child(blue_wash)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Frame"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 110)
	margin.add_theme_constant_override("margin_right", 110)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	# Header row: mode + title left, context (tournament + currencies) right.
	var header: HBoxContainer = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(header)

	var title_box: VBoxContainer = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	var mode_label: Label = make_accent_label("ADVENTURE MODE", 26, COLOR_GOLD)
	title_box.add_child(mode_label)
	var title_label: Label = make_display_label(_screen_title(), 58, COLOR_BONE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_box.add_child(title_label)

	var context_box: VBoxContainer = VBoxContainer.new()
	context_box.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(context_box)
	_context_label = make_accent_label(_context_text(), 24, COLOR_STEEL)
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	context_box.add_child(_context_label)

	column.add_child(_make_rule())

	_content_root = MarginContainer.new()
	_content_root.name = "Content"
	_content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_root.add_theme_constant_override("margin_top", 12)
	_content_root.add_theme_constant_override("margin_bottom", 12)
	column.add_child(_content_root)

	column.add_child(_make_rule())

	var footer: Label = make_accent_label(_footer_hints(), 22, COLOR_STEEL)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(footer)

func _context_text() -> String:
	if _flow == null:
		return ""
	var parts: Array[String] = []
	var tournament: String = String(_flow.call("tournament_label"))
	if tournament != "":
		parts.append(tournament)
	parts.append(String(_flow.call("currencies_label")))
	return "\n".join(parts)

func _make_rule() -> ColorRect:
	var rule: ColorRect = ColorRect.new()
	rule.custom_minimum_size = Vector2(0.0, 4.0)
	rule.color = COLOR_GOLD
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule

func _anchor_box(node: Control, left: float, right: float, top: float, bottom: float) -> void:
	node.anchor_left = left
	node.anchor_right = right
	node.anchor_top = top
	node.anchor_bottom = bottom
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

# ----------------------------------------------------------------- input ---

func _input(event: InputEvent) -> void:
	var back_pressed: bool = event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause_menu")
	if not back_pressed and event is InputEventJoypadButton:
		var pad: InputEventJoypadButton = event
		back_pressed = pad.pressed and pad.button_index == JOY_BUTTON_B
	if back_pressed and _on_back():
		_play_sfx("ui_click")
		get_viewport().set_input_as_handled()

func _grab_default_focus() -> void:
	var target: Control = _default_focus()
	if target != null and is_instance_valid(target):
		target.grab_focus()

# --------------------------------------------------------- widget helpers ---

func make_button(text: String, primary: bool = false, height: float = 84.0) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, height)
	btn.focus_mode = Control.FOCUS_ALL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var fill: Color = COLOR_BLOOD_RED if primary else COLOR_DARK_FILL
	if _palette != null and _palette.has_method("style_button"):
		_palette.call("style_button", btn, fill, COLOR_GOLD, COLOR_BONE, 30)
	btn.mouse_entered.connect(func() -> void:
		if btn.focus_mode != Control.FOCUS_NONE:
			btn.grab_focus()
	)
	btn.focus_entered.connect(_play_sfx.bind("ui_focus"))
	btn.pressed.connect(_play_sfx.bind("ui_click"))
	return btn

func make_panel(border: Color = COLOR_GOLD) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL_FILL
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(12)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	return panel

func make_display_label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	if _palette != null and _palette.has_method("style_display_label"):
		_palette.call("style_display_label", label, size, color)
	else:
		label.add_theme_font_size_override("font_size", size)
		label.add_theme_color_override("font_color", color)
	return label

func make_accent_label(text: String, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	if _palette != null and _palette.has_method("style_accent_label"):
		_palette.call("style_accent_label", label, size, color)
	else:
		label.add_theme_font_size_override("font_size", size)
		label.add_theme_color_override("font_color", color)
	return label

func make_heading(text: String, color: Color = COLOR_GOLD) -> Label:
	var label: Label = make_display_label(text, 36, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

## Placeholder logo badge: colored panel with a monogram, replaced by real
## art later (swap the monogram label for a TextureRect).
func make_logo_badge(monogram: String, color: Color, size: float = 150.0) -> PanelContainer:
	var badge: PanelContainer = make_panel(color)
	badge.custom_minimum_size = Vector2(size, size)
	var label: Label = make_display_label(monogram, int(size * 0.38), color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(label)
	return badge

## Vertical focus wiring with wraparound.
func wire_vertical(buttons: Array[Button]) -> void:
	var count: int = buttons.size()
	for index: int in range(count):
		var btn: Button = buttons[index]
		var above: Button = buttons[(index - 1 + count) % count]
		var below: Button = buttons[(index + 1) % count]
		btn.focus_neighbor_top = btn.get_path_to(above)
		btn.focus_neighbor_bottom = btn.get_path_to(below)
		btn.focus_previous = btn.get_path_to(above)
		btn.focus_next = btn.get_path_to(below)

## Horizontal wiring between two columns (index-paired, clamped).
func wire_columns(left: Array[Button], right: Array[Button]) -> void:
	for index: int in range(left.size()):
		if right.is_empty():
			break
		var pair: int = mini(index, right.size() - 1)
		left[index].focus_neighbor_right = left[index].get_path_to(right[pair])
	for index: int in range(right.size()):
		if left.is_empty():
			break
		var pair: int = mini(index, left.size() - 1)
		right[index].focus_neighbor_left = right[index].get_path_to(left[pair])

## "defensive_defenseman" -> "DEFENSIVE DEFENSEMAN" for display.
func archetype_text(archetype: StringName) -> String:
	return String(archetype).replace("_", " ").to_upper()

func advance() -> void:
	if _flow != null:
		_flow.call("advance", _flow.get("current_screen"))

func _play_sfx(sound_id: String) -> void:
	var sfx: Node = get_node_or_null("/root/SfxPlayer")
	if sfx != null and sfx.has_method("play"):
		sfx.call("play", sound_id)
