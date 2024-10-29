extends NPC

func _ready()->void:
	_setup()
	target_position = Vector2(32, -544)
	move_order.emit()
	await move_finished
	GlobalRes.main.test_room_combat_gate.emit("test_room_combat_gate")
	target_position = Vector2(288, -736)
	move_order.emit()
