extends State

func enter_state()->void:
	state_machine.user.stop_move = false
	var cur_target: Vector2 = state_machine.user.target_position
	var path: Array[Vector2] = NavMaster.request_nav_path(state_machine.user.position, cur_target)
	if path.pop_front() != state_machine.user.position:
		path = []
	for pos in path:
		if state_machine.user.cur_ap == 0:
			EventBus.broadcast(EventBus.Event.new("PRINT_LOG","No ap for movement!"))
			break
		if state_machine.user.stop_move:
			state_machine.user.target_position = state_machine.user.position
			break
		var prev_pos: Vector2 = state_machine.user.position
		EventBus.broadcast(EventBus.Event.new("TILE_OCCUPIED", pos))
		await create_tween().tween_property(state_machine.user, "position", pos, .2).finished
		EventBus.broadcast(EventBus.Event.new("TILE_UNOCCUPIED", prev_pos))
		if state_machine.user.in_combat:
			state_machine.user.cur_ap -= 1
			state_machine.user.stats_changed.emit()
		if cur_target != state_machine.user.target_position:
			break
	state_machine.user.stop_move = false
	if state_machine.user.interact_target != null:
		state_machine.change_state_to("INTERACT")
	else:
		state_machine.change_state_to("IDLE")

func exit_state()->void:
	state_machine.user.move_finished.emit()
