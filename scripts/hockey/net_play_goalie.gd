extends "res://scripts/hockey/goalie_controller.gd"

const RinkGeometry: GDScript = preload("res://scripts/hockey/rink_geometry.gd")

@export var post_seal_offset: float = 1.18
@export var behind_net_poke_radius: float = 1.85

func _pick_target_z() -> float:
	if _puck == null:
		return 0.0
	var puck_node: Node3D = _puck as Node3D
	if puck_node == null:
		return 0.0
	var puck_position: Vector3 = puck_node.global_position
	var behind_this_net: bool = puck_position.x * guard_side > RinkGeometry.GOAL_LINE_X + 0.15
	if behind_this_net:
		return clampf(signf(puck_position.z if absf(puck_position.z) > 0.05 else 1.0) * post_seal_offset, -crease_half_width, crease_half_width)
	return super._pick_target_z()

func _update_block() -> void:
	if _puck == null:
		return
	var puck_node: Node3D = _puck as Node3D
	if puck_node != null:
		var behind_this_net: bool = puck_node.global_position.x * guard_side > RinkGeometry.GOAL_LINE_X + 0.10
		var distance: float = Vector3(puck_node.global_position.x - global_position.x, 0.0, puck_node.global_position.z - global_position.z).length()
		if behind_this_net and distance <= behind_net_poke_radius and _save_cooldown_timer <= 0.0:
			var clear: Vector3 = Vector3(-guard_side, 0.0, signf(puck_node.global_position.z) * 0.9).normalized()
			_puck.call("poke_free", clear, crash_clear_speed)
			_register_save()
			return
	super._update_block()
