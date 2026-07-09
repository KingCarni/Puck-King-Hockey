extends Control

# Single upgrade card used by the reward draft.
# Big, controller-friendly. Hover/focus pops the card with a gold glow.

signal card_chosen(index: int, upgrade_id: String)

@export var card_index: int = 0
@export var upgrade_id: String = ""
@export var card_title: String = "UPGRADE"
@export var card_description: String = "Does cool stuff."
@export var hotkey_label: String = "1"
@export var controller_label: String = "A"
@export var icon_path: String = ""

const HOVER_SCALE: Vector2 = Vector2(1.05, 1.05)
const REST_SCALE: Vector2 = Vector2(1.0, 1.0)
const HOVER_TIME: float = 0.12
const CARD_SIZE: Vector2 = Vector2(350.0, 500.0)

var _palette: Node = null
var _panel: PanelContainer = null
var _ribbon: PanelContainer = null
var _ribbon_label: Label = null
var _title_label: Label = null
var _description_label: Label = null
var _hotkey_pill: PanelContainer = null
var _hotkey_label_node: Label = null
var _icon_glyph: Label = null
var _icon_rect: TextureRect = null
var _button: Button = null
var _hover_tween: Tween = null
var _is_focused: bool = false

func _ready() -> void:
	_palette = get_node_or_null("/root/UiPalette")
	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE * 0.5
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_ui()
	_refresh_text()

func configure(index: int, id: String, title: String, description: String, hotkey: String = "", controller: String = "", icon: String = "") -> void:
	card_index = index
	upgrade_id = id
	card_title = title
	card_description = description
	if hotkey != "":
		hotkey_label = hotkey
	if controller != "":
		controller_label = controller
	icon_path = icon
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
	panel_style.content_margin_left = 22
	panel_style.content_margin_right = 22
	panel_style.content_margin_top = 22
	panel_style.content_margin_bottom = 22
	_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "Content"
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)

	_ribbon = PanelContainer.new()
	_ribbon.name = "Ribbon"
	_ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var ribbon_style: StyleBoxFlat = StyleBoxFlat.new()
	ribbon_style.bg_color = Color(0.85, 0.10, 0.13, 1.0)
	ribbon_style.border_color = Color(1.0, 0.92, 0.30, 1.0)
	ribbon_style.set_border_width_all(3)
	ribbon_style.set_corner_radius_all(6)
	ribbon_style.content_margin_left = 18
	ribbon_style.content_margin_right = 18
	ribbon_style.content_margin_top = 7
	ribbon_style.content_margin_bottom = 7
	_ribbon.add_theme_stylebox_override("panel", ribbon_style)
	vbox.add_child(_ribbon)

	_ribbon_label = Label.new()
	_ribbon_label.name = "RibbonLabel"
	_ribbon_label.text = "PICK"
	_ribbon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ribbon.add_child(_ribbon_label)

	var icon_panel: PanelContainer = PanelContainer.new()
	icon_panel.name = "IconArea"
	icon_panel.custom_minimum_size = Vector2(0.0, 126.0)
	icon_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon_style: StyleBoxFlat = StyleBoxFlat.new()
	icon_style.bg_color = Color(0.12, 0.12, 0.14, 1.0)
	icon_style.border_color = Color(0.55, 0.58, 0.62, 1.0)
	icon_style.set_border_width_all(2)
	icon_style.set_corner_radius_all(8)
	icon_panel.add_theme_stylebox_override("panel", icon_style)
	vbox.add_child(icon_panel)

	_icon_rect = TextureRect.new()
	_icon_rect.name = "IconTexture"
	_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.visible = false
	icon_panel.add_child(_icon_rect)

	_icon_glyph = Label.new()
	_icon_glyph.name = "IconGlyph"
	_icon_glyph.text = "★"
	_icon_glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_panel.add_child(_icon_glyph)

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

	_hotkey_pill = PanelContainer.new()
	_hotkey_pill.name = "HotkeyPill"
	_hotkey_pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var pill_style: StyleBoxFlat = StyleBoxFlat.new()
	pill_style.bg_color = Color(0.05, 0.05, 0.06, 1.0)
	pill_style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	pill_style.set_border_width_all(3)
	pill_style.set_corner_radius_all(22)
	pill_style.content_margin_left = 22
	pill_style.content_margin_right = 22
	pill_style.content_margin_top = 7
	pill_style.content_margin_bottom = 7
	_hotkey_pill.add_theme_stylebox_override("panel", pill_style)
	vbox.add_child(_hotkey_pill)

	_hotkey_label_node = Label.new()
	_hotkey_label_node.name = "HotkeyText"
	_hotkey_label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hotkey_pill.add_child(_hotkey_label_node)

	_button = Button.new()
	_button.name = "ChooseButton"
	_button.text = "CHOOSE"
	_button.focus_mode = Control.FOCUS_ALL
	_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_button)
	_button.pressed.connect(_on_choose_pressed)
	_button.focus_entered.connect(_on_focus_entered)
	_button.focus_exited.connect(_on_focus_exited)
	button_down.connect(_on_focus_entered)
	button_up.connect(_on_focus_exited)

	if _palette != null:
		_palette.style_accent_label(_ribbon_label, 20, _palette.COLOR_BONE)
		_palette.style_display_label(_icon_glyph, 72, _palette.COLOR_GOLD)
		_palette.style_display_label(_title_label, 30, _palette.COLOR_BONE)
		_palette.style_accent_label(_description_label, 18, _palette.COLOR_STEEL)
		_palette.style_accent_label(_hotkey_label_node, 20, _palette.COLOR_GOLD)
		_palette.style_button(_button, Color(0.85, 0.10, 0.13, 1.0), _palette.COLOR_GOLD, _palette.COLOR_BONE, 22)

func _refresh_text() -> void:
	if _title_label != null:
		_title_label.text = card_title
	if _description_label != null:
		_description_label.text = card_description
	if _hotkey_label_node != null:
		_hotkey_label_node.text = "%s / %s" % [hotkey_label, controller_label]
	if _icon_glyph != null:
		_icon_glyph.text = _glyph_for_upgrade(upgrade_id)
	if _icon_rect != null:
		var texture: Texture2D = _load_icon_texture(icon_path)
		_icon_rect.texture = texture
		_icon_rect.visible = texture != null
		_icon_glyph.visible = texture == null

func grab_card_focus() -> void:
	if _button != null:
		_button.grab_focus()

func _on_choose_pressed() -> void:
	emit_signal("card_chosen", card_index, upgrade_id)

func _on_focus_entered() -> void:
	if _is_focused:
		return
	_is_focused = true
	_animate_scale(HOVER_SCALE)

func _on_focus_exited() -> void:
	if not _is_focused:
		return
	_is_focused = false
	_animate_scale(REST_SCALE)

func _animate_scale(target: Vector2) -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", target, HOVER_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _load_icon_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _glyph_for_upgrade(id: String) -> String:
	match id:
		"rocket_skates": return "⚡"
		"sticky_tape": return "✦"
		"titanium_pads": return "⚔"
		"rocket_shot": return "🔥"
		"magnet_puck": return "🧲"
		"freeze_blast": return "❄"
	return "★"
