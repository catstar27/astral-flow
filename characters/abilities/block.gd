extends Ability

func activate(_destination: Vector2)->void:
	user.stat_mods.defense += 2
	activated.emit()
