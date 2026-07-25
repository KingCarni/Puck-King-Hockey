extends Node

# Manual test: drives AdventureFlow through the full tournament loop with
# placeholder results, screenshotting every screen. Run windowed:
#   godot --path . res://tests/manual/AdventureProbe.tscn ++ --out-dir <dir>
# Spawns the driver as a root child so scene changes don't kill it.

const DriverScript: GDScript = preload("res://tests/manual/adventure_probe_driver.gd")

func _ready() -> void:
	var driver: Node = Node.new()
	driver.name = "AdventureProbeDriver"
	driver.set_script(DriverScript)
	get_tree().root.add_child.call_deferred(driver)
