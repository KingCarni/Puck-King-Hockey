extends CanvasLayer

# Reward Draft modal.
# - Three big arcade upgrade cards.
# - Mouse, keyboard (1/2/3), and controller (A/X/Y, D-pad, focus) support.
# - Emits "upgrade_selected(index, upgrade_id)" when the player picks one.

signal upgrade_selected(index: int, upgrade_id: String)

const UpgradeCardScript: GDScript = preload("res://scripts/ui/upgrade_card.gd")

const HOTKEYS: Array[String] = ["1", "2", "3"]
const CONTROLLER_BUTTONS: Array[String] = ["A", "X", "Y"]

var _palette: Node = null
var _root: Control = null
var _shade: ColorRect = null
var _frame: PanelContainer = null
var _title_label: Label = null
var _subtitle_label: Label = null
var _hint_label: Label = null
var _cards_row: HBoxContainer = null
var _cards: Array[Control] = []
var _options: Array[Dictionary] = []
var _is_open: bool = false

func _ready() -> void:
	layer = 50
	_palette = get_node_or_null("/root/UiPalette")
	_build_ui()
	hide_draft()

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "RewardRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.0, 0.0, 0.0, 0.78)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_shade)

	_frame = PanelContainer.new()
	_frame.name = "Frame"
	_frame.anchor_left = 0.5
	_frame.anchor_top = 0.5
	_frame.anchor_right = 0.5
	_frame.anchor_bottom = 0.5
	_frame.offset_left = -880.0
	_frame.offset_right = 880.0
	_frame.offset_top = -440.0
	_frame.offset_bottom = 440.0
	_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	_root.add_child(_frame)

	var frame_style: StyleBoxFlat = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.05, 0.05, 0.06, 0.97)
	frame_style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	frame_style.set_border_width_all(6)
	frame_style.set_corner_radius_all(18)
	frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	frame_style.shadow_size = 22
	frame_style.content_margin_left = 40
	frame_style.content_margin_right = 40
	frame_style.content_margin_top = 32
	frame_style.content_margin_bottom = 32
	_frame.add_theme_stylebox_override("panel", frame_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "Layout"
	vbox.add_theme_constant_override("separation", 18)
	_frame.add_child(vbox)

	# Header banner.
	var header_panel: PanelContainer = PanelContainer.new()
	header_panel.name = "HeaderBanner"
	var header_style: StyleBoxFlat = StyleBoxFlat.new()
	header_style.bg_color = Color(0.85, 0.10, 0.13, 1.0)
	header_style.border_color = Color(1.0, 0.92, 0.30, 1.0)
	header_style.set_border_width_all(4)
	header_style.set_corner_radius_all(8)
	header_style.content_margin_left = 28
	header_style.content_margin_right = 28
	header_style.content_margin_top = 12
	header_style.content_margin_bottom = 12
	header_panel.add_theme_stylebox_override("panel", header_style)
	vbox.add_child(header_panel)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "REWARD DRAFT"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_panel.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "Subtitle"
	_subtitle_label.text = "PICK ONE — KEEP IT FOR THE MATCH"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_subtitle_label)

	_cards_row = HBoxContainer.new()
	_cards_row.name = "CardsRow"
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", 36)
	_cards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_cards_row)

	_hint_label = Label.new()
	_hint_label.name = "Hint"
	_hint_label.text = "MOUSE CLICK  •  KEYS 1 / 2 / 3  •  PAD A / X / Y"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hint_label)

	if _palette != null:
		_palette.style_display_label(_title_label, 56, _palette.COLOR_BONE)
		_palette.style_accent_label(_subtitle_label, 28, _palette.COLOR_GOLD)
		_palette.style_accent_label(_hint_label, 22, _palette.COLOR_STEEL)

func set_options(options: Array) -> void:
	_options.clear()
	for option in options:
		if option is Dictionary:
			_options.append(option)

	# Re-build cards to match option count.
	_rebuild_cards()

func _rebuild_cards() -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()

	for index in range(_options.size()):
		var option: Dictionary = _options[index]
		var card: Control = Control.new()
		card.set_script(UpgradeCardScript)
		_cards_row.add_child(card)
		card.configure(
			index,
			String(option.get("title", "UPGRADE")),
			String(option.get("description", "")),
			HOTKEYS[index] if index < HOTKEYS.size() else str(index + 1),
			CONTROLLER_BUTTONS[index] if index < CONTROLLER_BUTTONS.size() else "—"
		)
		card.card_chosen.connect(_on_card_chosen)
		_cards.append(card)

func show_draft() -> void:
	_is_open = true
	visible = true
	_root.modulate.a = 0.0
	_frame.scale = Vector2(0.86, 0.86)
	_frame.pivot_offset = Vector2(880.0, 440.0)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_root, "modulate:a", 1.0, 0.18)
	tween.tween_property(_frame, "scale", Vector2(1.0, 1.0), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(Callable(self, "_focus_first_card"))

func hide_draft() -> void:
	_is_open = false
	visible = false

func _focus_first_card() -> void:
	if _cards.is_empty():
		return
	if _cards[0].has_method("grab_card_focus"):
		_cards[0].call("grab_card_focus")

func _on_card_chosen(index: int) -> void:
	if not _is_open:
		return
	if index < 0 or index >= _options.size():
		return
	var option: Dictionary = _options[index]
	emit_signal("upgrade_selected", index, String(option.get("id", "")))

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		var hotkey_index: int = _key_to_index(key_event.keycode)
		if hotkey_index >= 0:
			_on_card_chosen(hotkey_index)
			get_viewport().set_input_as_handled()

	elif event is InputEventJoypadButton:
		var pad_event: InputEventJoypadButton = event as InputEventJoypadButton
		if not pad_event.pressed:
			return
		var pad_index: int = _pad_to_index(pad_event.button_index)
		if pad_index >= 0:
			_on_card_chosen(pad_index)
			get_viewport().set_input_as_handled()

func _key_to_index(keycode: int) -> int:
	if keycode == KEY_1:
		return 0
	if keycode == KEY_2:
		return 1
	if keycode == KEY_3:
		return 2
	return -1

func _pad_to_index(button_index: int) -> int:
	if button_index == JOY_BUTTON_A:
		return 0
	if button_index == JOY_BUTTON_X:
		return 1
	if button_index == JOY_BUTTON_Y:
		return 2
	return -1
