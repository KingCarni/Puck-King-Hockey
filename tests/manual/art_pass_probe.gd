extends Node

# Manual test: loads the match scene, waits for it to settle, saves a
# screenshot, then quits. Run windowed (not --headless):
#   godot --path . res://tests/manual/ArtPassProbe.tscn
# Optional: --screenshot-path <absolute path> (defaults to user://art_pass_probe.png)

const TARGET_SCENE: String = "res://scenes/match/TestRink.tscn"
const CAPTURE_FRAME: int = 90

var _frames: int = 0
var _output_path: String = "user://art_pass_probe.png"

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for index: int in range(args.size() - 1):
		if args[index] == "--screenshot-path":
			_output_path = args[index + 1]

	var scene: Node = (load(TARGET_SCENE) as PackedScene).instantiate()
	add_child(scene)

func _process(_delta: float) -> void:
	_frames += 1
	if _frames == CAPTURE_FRAME:
		var image: Image = get_viewport().get_texture().get_image()
		var error: int = image.save_png(_output_path)
		print("art_pass_probe: saved %s (error=%d)" % [_output_path, error])
	elif _frames > CAPTURE_FRAME + 5:
		get_tree().quit()
