extends Ability

func activate(destination: Vector2)->void:
	play_sound()
	deal_damage(get_target(destination))
	activated.emit()
