extends Ability

func activate(_destination: Vector2)->void:
	user.damage_reduction = 1
	activated.emit()
