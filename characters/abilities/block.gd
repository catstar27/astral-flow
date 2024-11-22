extends Ability

func activate(_destination: Vector2)->void:
	user.stat_mods.lesser_dt += 1
	activated.emit()
