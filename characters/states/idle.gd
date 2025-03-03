extends State
## Idle state that does nothing but moves to other states

func enter_state(_data)->void:
	state_machine.user.move_order.connect(start_move)
	state_machine.user.interact_order.connect(start_interact)
	state_machine.user.ability_order.connect(start_ability)

func exit_state()->void:
	state_machine.user.move_order.disconnect(start_move)
	state_machine.user.interact_order.disconnect(start_interact)
	state_machine.user.ability_order.disconnect(start_ability)

func start_move(pos: Vector2)->void:
	state_machine.change_state_to("MOVE", pos)

func start_interact(target: Node2D)->void:
	state_machine.change_state_to("INTERACT", target)

func start_ability(data: Array)->void:
	state_machine.change_state_to("ACTIVATE_ABILITY", data)
