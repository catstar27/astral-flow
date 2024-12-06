extends State

func enter_state(target: Node2D)->void:
	if target is Interactive:
		for pos in target.occupied_positions:
			var x_dist: float = abs(state_machine.user.position.x-pos.x)
			var y_dist: float = abs(state_machine.user.position.y-pos.y)
			var range_factor: float = (x_dist+y_dist)/Settings.tile_size
			if range_factor <= 1:
				target.call_deferred("_interacted", state_machine.user)
				break
	else:
		var x_dist: float = abs(state_machine.user.position.x-target.position.x)
		var y_dist: float = abs(state_machine.user.position.y-target.position.y)
		var range_factor: float = (x_dist+y_dist)/Settings.tile_size
		if range_factor <= 1:
			target.call_deferred("_interacted", state_machine.user)
	state_machine.change_state_to("IDLE")
