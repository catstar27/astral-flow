extends Ability

func activate(destination: Vector2)->void:
	deal_damage(get_target(destination))
