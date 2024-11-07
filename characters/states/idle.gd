extends State

func enter_state()->void:
	state_machine.user.move_processed.connect(start_move)
	state_machine.user.interact_processed.connect(start_interact)

func exit_state()->void:
	state_machine.user.move_processed.disconnect(start_move)
	state_machine.user.interact_processed.disconnect(start_interact)

func start_move()->void:
	state_machine.change_state_to("MOVE")

func start_interact()->void:
	state_machine.change_state_to("INTERACT")
