extends Node

# Manual test: boots the main menu, screenshots it, presses ENTER (Play holds
# default focus) and screenshots the scene that loads, proving the Play
# transition works. Run windowed (not --headless):
#   godot --path . res://tests/manual/MenuProbe.tscn
# Optional: ++ --out-dir <absolute dir> (defaults to user://)

const MENU_SCENE_PATH: String = "res://scenes/ui/MainMenu.tscn"
const MENU_CAPTURE_FRAME: int = 90
const PRESS_FRAME: int = 110
const RELEASE_FRAME: int = 116
const MATCH_CAPTURE_FRAME: int = 320

var _frames: int = 0
var _out_dir: String = "user://"

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for index: int in range(args.size() - 1):
		if args[index] == "--out-dir":
			_out_dir = args[index + 1]

	var menu: Node = (load(MENU_SCENE_PATH) as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(menu)
	_adopt_as_current.call_deferred(menu)

func _adopt_as_current(menu: Node) -> void:
	# The probe stays a plain root child so Play's change_scene_to_file()
	# frees the menu, not the probe.
	get_tree().current_scene = menu

func _process(_delta: float) -> void:
	_frames += 1
	if _frames == MENU_CAPTURE_FRAME:
		_capture("menu_probe_menu.png")
	elif _frames == PRESS_FRAME:
		_send_enter(true)
	elif _frames == RELEASE_FRAME:
		_send_enter(false)
	elif _frames == MATCH_CAPTURE_FRAME:
		_capture("menu_probe_match.png")
		print("menu_probe: current scene after Play = %s" % get_tree().current_scene.scene_file_path)
	elif _frames > MATCH_CAPTURE_FRAME + 5:
		get_tree().quit()

func _capture(file_name: String) -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var path: String = _out_dir.path_join(file_name)
	var error: int = image.save_png(path)
	print("menu_probe: saved %s (error=%d)" % [path, error])

func _send_enter(pressed: bool) -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_ENTER
	key.physical_keycode = KEY_ENTER
	key.pressed = pressed
	Input.parse_input_event(key)
