extends Ability

func activate(destination: Vector2)->void:
	print(destination)
	print(get_target(destination))
	deal_damage(get_target(destination))
	activated.emit()
