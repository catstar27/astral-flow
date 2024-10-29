extends NPC

func _ready()->void:
	_setup()
	target_position = Vector2(32, -544)
	move_order.emit()
	await move_finished
	target_position = Vector2(288, -736)
	move_order.emit()
