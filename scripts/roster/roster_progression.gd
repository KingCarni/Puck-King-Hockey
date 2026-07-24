class_name RosterProgression
extends RefCounted

# Permanent Adventure Mode progression — save-data interface stub.
#
# Future save system loads earned upgrades per character and returns them as
# modifier dictionaries using the ability convention ("<stat>_mult" /
# "<stat>_add"), e.g. {&"max_speed_mult": 0.04, &"pass_accuracy_add": 0.05}.
# PlayerRuntimeStats folds these into the permanent layer, so no other code
# changes when real persistence lands.

const SAVE_PATH: String = "user://roster_progression.cfg"

static func load_modifiers(_progression_key: StringName) -> Dictionary:
	# No persistence yet: every character starts unprogressed.
	return {}

static func save_modifiers(_progression_key: StringName, _modifiers: Dictionary) -> void:
	# Intentionally empty until Adventure Mode ships a real save system.
	pass
