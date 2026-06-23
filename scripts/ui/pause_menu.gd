extends CanvasLayer

# Pause menu: Resume, Restart Match, Quit To Menu.
# Triggered by ESC or controller Start. Always processes (works during pause).

signal resume_requested
signal restart_requested
signal quit_requested

var _palette: Node = null
var _root: Control = null
var _shade: ColorRect = null
var _frame: PanelContainer = null
var _resume_button: Button = null
var _restart_button: Button = null
var _quit_button: Button = null
var _is_open: bool = false

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_palette = get_node_or_null("/root/UiPalette")
	_build_ui()
	close()

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "PauseRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.0, 0.0, 0.0, 0.78)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_shade)

	_frame = PanelContainer.new()
	_frame.name = "Frame"
	_frame.anchor_left = 0.5
	_frame.anchor_top = 0.5
	_frame.anchor_right = 0.5
	_frame.anchor_bottom = 0.5
	_frame.offset_left = -380.0
	_frame.offset_right = 380.0
	_frame.offset_top = -340.0
	_frame.offset_bottom = 340.0
	_root.add_child(_frame)

	var frame_style: StyleBoxFlat = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.05, 0.05, 0.06, 0.98)
	frame_style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	frame_style.set_border_width_all(6)
	frame_style.set_corner_radius_all(16)
	frame_style.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	frame_style.shadow_size = 22
	frame_style.content_margin_left = 40
	frame_style.content_margin_right = 40
	frame_style.content_margin_top = 36
	frame_style.content_margin_bottom = 36
	_frame.add_theme_stylebox_override("panel", frame_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "Layout"
	vbox.add_theme_constant_override("separation", 22)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_frame.add_child(vbox)

	# Header ribbon.
	var header_panel: PanelContainer = PanelContainer.new()
	header_panel.name = "HeaderRibbon"
	var header_style: StyleBoxFlat = StyleBoxFlat.new()
	header_style.bg_color = Color(0.85, 0.10, 0.13, 1.0)
	header_style.border_color = Color(1.0, 0.92, 0.30, 1.0)
	header_style.set_border_width_all(4)
	header_style.set_corner_radius_all(8)
	header_style.content_margin_left = 28
	header_style.content_margin_right = 28
	header_style.content_margin_top = 14
	header_style.content_margin_bottom = 14
	header_panel.add_theme_stylebox_override("panel", header_style)
	vbox.add_child(header_panel)

	var title_label: Label = Label.new()
	title_label.name = "Title"
	title_label.text = "PAUSED"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_panel.add_child(title_label)

	var subtitle_label: Label = Label.new()
	subtitle_label.name = "Subtitle"
	subtitle_label.text = "CATCH YOUR BREATH"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle_label)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 12.0)
	vbox.add_child(spacer)

	_resume_button = _make_button("RESUME", Color(0.85, 0.10, 0.13, 1.0))
	_restart_button = _make_button("RESTART MATCH", Color(0.10, 0.10, 0.12, 1.0))
	_quit_button = _make_button("QUIT TO MENU", Color(0.10, 0.10, 0.12, 1.0))

	vbox.add_child(_resume_button)
	vbox.add_child(_restart_button)
	vbox.add_child(_quit_button)

	_resume_button.pressed.connect(_on_resume_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	var hint_label: Label = Label.new()
	hint_label.name = "Hint"
	hint_label.text = "ESC OR START TO RESUME"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint_label)

	if _palette != null:
		_palette.style_display_label(title_label, 64, _palette.COLOR_BONE)
		_palette.style_accent_label(subtitle_label, 22, _palette.COLOR_GOLD)
		_palette.style_accent_label(hint_label, 18, _palette.COLOR_STEEL)

func _make_button(text: String, fill: Color) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420.0, 70.0)
	button.focus_mode = Control.FOCUS_ALL
	if _palette != null:
		_palette.style_button(button, fill, _palette.COLOR_GOLD, _palette.COLOR_BONE, 30)
	return button

func open() -> void:
	_is_open = true
	visible = true
	get_tree().paused = true
	_root.modulate.a = 0.0
	_frame.scale = Vector2(0.85, 0.85)
	_frame.pivot_offset = Vector2(380.0, 340.0)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_root, "modulate:a", 1.0, 0.16)
	tween.tween_property(_frame, "scale", Vector2(1.0, 1.0), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_callback(Callable(self, "_focus_resume"))

func close() -> void:
	_is_open = false
	visible = false
	get_tree().paused = false

func is_open() -> bool:
	return _is_open

func toggle() -> void:
	if _is_open:
		_on_resume_pressed()
	else:
		open()

func _focus_resume() -> void:
	if _resume_button != null:
		_resume_button.grab_focus()

func _on_resume_pressed() -> void:
	close()
	emit_signal("resume_requested")

func _on_restart_pressed() -> void:
	close()
	emit_signal("restart_requested")

func _on_quit_pressed() -> void:
	close()
	emit_signal("quit_requested")

func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("pause_menu"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()
