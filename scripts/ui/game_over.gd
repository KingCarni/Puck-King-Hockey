extends CanvasLayer

# Game over modal: shows winner, scores, options to rematch or return to menu.

signal rematch_requested
signal main_menu_requested

const MAIN_MENU_PATH: String = "res://scenes/ui/MainMenu.tscn"

var _palette: Node = null
var _root: Control = null
var _frame: PanelContainer = null
var _title_label: Label = null
var _score_label: Label = null
var _stars_label: Label = null
var _rematch_button: Button = null
var _menu_button: Button = null
var _is_open: bool = false

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	_palette = get_node_or_null("/root/UiPalette")
	_build_ui()
	hide()

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.82)
	_root.add_child(shade)

	_frame = PanelContainer.new()
	_frame.anchor_left = 0.5
	_frame.anchor_right = 0.5
	_frame.anchor_top = 0.5
	_frame.anchor_bottom = 0.5
	_frame.offset_left = -540.0
	_frame.offset_right = 540.0
	_frame.offset_top = -360.0
	_frame.offset_bottom = 360.0
	_root.add_child(_frame)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08, 0.98)
	style.border_color = Color(1.0, 0.78, 0.10, 1.0)
	style.set_border_width_all(6)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	style.shadow_size = 22
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 32
	style.content_margin_bottom = 32
	_frame.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 22)
	_frame.add_child(vbox)

	var ribbon: PanelContainer = PanelContainer.new()
	var ribbon_style: StyleBoxFlat = StyleBoxFlat.new()
	ribbon_style.bg_color = Color(0.85, 0.10, 0.13, 1.0)
	ribbon_style.border_color = Color(1.0, 0.92, 0.30, 1.0)
	ribbon_style.set_border_width_all(4)
	ribbon_style.set_corner_radius_all(8)
	ribbon_style.content_margin_left = 28
	ribbon_style.content_margin_right = 28
	ribbon_style.content_margin_top = 12
	ribbon_style.content_margin_bottom = 12
	ribbon.add_theme_stylebox_override("panel", ribbon_style)
	vbox.add_child(ribbon)

	_title_label = Label.new()
	_title_label.text = "MATCH OVER"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.add_child(_title_label)

	_score_label = Label.new()
	_score_label.text = "0 — 0"
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_score_label)

	_stars_label = Label.new()
	_stars_label.text = ""
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stars_label.visible = false
	vbox.add_child(_stars_label)

	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 18.0)
	vbox.add_child(spacer)

	_rematch_button = _make_button("REMATCH", Color(0.85, 0.10, 0.13, 1.0))
	_menu_button = _make_button("RETURN TO MENU", Color(0.10, 0.10, 0.12, 1.0))
	vbox.add_child(_rematch_button)
	vbox.add_child(_menu_button)

	_rematch_button.pressed.connect(_on_rematch_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)

	if _palette != null:
		_palette.style_display_label(_title_label, 70, _palette.COLOR_BONE)
		_palette.style_display_label(_score_label, 120, _palette.COLOR_HOT_GOLD)
		_palette.style_accent_label(_stars_label, 26, _palette.COLOR_GOLD)

# Three-stars / MVP block. Pass display lines like "★ P1 CAPTAIN — 2 G, 3 HIT".
func set_three_stars(lines: Array) -> void:
	if _stars_label == null:
		return
	if lines.is_empty():
		_stars_label.visible = false
		return
	var text_lines: Array[String] = []
	for line in lines:
		text_lines.append(String(line))
	_stars_label.text = "\n".join(text_lines)
	_stars_label.visible = true

func _make_button(text: String, fill: Color) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(440.0, 78.0)
	btn.focus_mode = Control.FOCUS_ALL
	if _palette != null:
		_palette.style_button(btn, fill, _palette.COLOR_GOLD, _palette.COLOR_BONE, 30)
	return btn

func open(winner: String, home_score: int, away_score: int) -> void:
	_is_open = true
	visible = true
	get_tree().paused = true

	# Adventure matches continue the tournament instead of offering a rematch.
	var adventure: bool = _is_adventure_match()
	_rematch_button.visible = not adventure
	_menu_button.text = "CONTINUE TOURNAMENT" if adventure else "RETURN TO MENU"

	var headline: String = "MATCH OVER"
	if winner == "HOME":
		headline = "YOU WIN!"
	elif winner == "AWAY":
		headline = "YOU LOSE"
	elif winner == "DRAW":
		headline = "DRAW"
	_title_label.text = headline
	_score_label.text = "%d — %d" % [home_score, away_score]

	_frame.scale = Vector2(0.85, 0.85)
	_frame.pivot_offset = Vector2(540.0, 360.0)
	_root.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_root, "modulate:a", 1.0, 0.18)
	tween.tween_property(_frame, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	var focus_target: Button = _rematch_button if _rematch_button.visible else _menu_button
	tween.tween_callback(Callable(focus_target, "grab_focus"))

func close() -> void:
	_is_open = false
	visible = false
	get_tree().paused = false

func _on_rematch_pressed() -> void:
	if has_node("/root/SfxPlayer"):
		SfxPlayer.play(SfxPlayer.ID_UI_CLICK)
	close()
	emit_signal("rematch_requested")

func _on_menu_pressed() -> void:
	if has_node("/root/SfxPlayer"):
		SfxPlayer.play(SfxPlayer.ID_UI_CLICK)
	close()
	if _is_adventure_match():
		var flow: Node = get_node_or_null("/root/AdventureFlow")
		flow.call("on_match_finished")
		return
	emit_signal("main_menu_requested")
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _is_adventure_match() -> bool:
	var flow: Node = get_node_or_null("/root/AdventureFlow")
	return flow != null and flow.has_method("is_adventure_match") and bool(flow.call("is_adventure_match"))
