extends Control

const MAIN_MENU_PATH: String = "res://scenes/ui/MainMenu.tscn"
const LOGO_WEBP_PATH: String = "res://assets/ui/title_screen/pkh_logo_splash.webp"
const LOGO_PNG_PATH: String = "res://assets/ui/title_screen/pkh_logo_splash.png"
const SPLASH_DURATION: float = 2.25

var _elapsed: float = 0.0
var _can_skip: bool = false
var _logo_node: CanvasItem = null
var _prompt: Label = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_screen()
	_fade_in()
	var timer: SceneTreeTimer = get_tree().create_timer(0.45)
	timer.timeout.connect(func() -> void:
		_can_skip = true
	)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= SPLASH_DURATION:
		_go_to_menu()

func _unhandled_input(event: InputEvent) -> void:
	if not _can_skip:
		return
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			_go_to_menu()
	elif event is InputEventJoypadButton:
		var pad_event: InputEventJoypadButton = event as InputEventJoypadButton
		if pad_event.pressed:
			_go_to_menu()
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed:
			_go_to_menu()

func _build_screen() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.name = "Blackout"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 1.0)
	add_child(bg)

	var texture: Texture2D = _load_logo_texture()
	if texture != null:
		var logo: TextureRect = TextureRect.new()
		logo.name = "LogoSplash"
		logo.texture = texture
		logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		logo.offset_left = 260.0
		logo.offset_right = -260.0
		logo.offset_top = 150.0
		logo.offset_bottom = -210.0
		logo.modulate.a = 0.0
		_logo_node = logo
		add_child(logo)
	else:
		var fallback: Label = Label.new()
		fallback.name = "FallbackLogo"
		fallback.text = "PUCK KING\nHELL"
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.add_theme_font_size_override("font_size", 116)
		fallback.modulate = Color(1.0, 0.95, 0.82, 0.0)
		_logo_node = fallback
		add_child(fallback)

	_prompt = Label.new()
	_prompt.name = "SkipPrompt"
	_prompt.text = "PRESS ANY BUTTON"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.anchor_left = 0.0
	_prompt.anchor_right = 1.0
	_prompt.anchor_top = 1.0
	_prompt.anchor_bottom = 1.0
	_prompt.offset_top = -110.0
	_prompt.offset_bottom = -60.0
	_prompt.add_theme_font_size_override("font_size", 26)
	_prompt.modulate = Color(0.75, 0.78, 0.82, 0.0)
	add_child(_prompt)

func _fade_in() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	if _logo_node != null:
		tween.tween_property(_logo_node, "modulate:a", 1.0, 0.45)
	if _prompt != null:
		tween.tween_property(_prompt, "modulate:a", 0.70, 0.85).set_delay(0.80)

func _go_to_menu() -> void:
	set_process(false)
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _load_logo_texture() -> Texture2D:
	if ResourceLoader.exists(LOGO_WEBP_PATH):
		return load(LOGO_WEBP_PATH) as Texture2D
	if ResourceLoader.exists(LOGO_PNG_PATH):
		return load(LOGO_PNG_PATH) as Texture2D
	return null
