extends State

var stop_movement: bool = false

func enter_state(data: Vector2)->void:
	stop_movement = false
	state_machine.user.stop_move_order.connect(stop)
	var cur_target: Vector2 = data
	var path: Array[Vector2] = NavMaster.request_nav_path(state_machine.user.position, cur_target)
	if path.pop_front() != state_machine.user.position:
		path = []
	for pos in path:
		if state_machine.user.cur_ap == 0:
			EventBus.broadcast(EventBus.Event.new("PRINT_LOG","No ap for movement!"))
			break
		if stop_movement:
			break
		var prev_pos: Vector2 = state_machine.user.position
		EventBus.broadcast(EventBus.Event.new("TILE_OCCUPIED", pos))
		await create_tween().tween_property(state_machine.user, "position", pos, .2).finished
		EventBus.broadcast(EventBus.Event.new("TILE_UNOCCUPIED", prev_pos))
		if state_machine.user.in_combat:
			state_machine.user.cur_ap -= 1
			state_machine.user.stats_changed.emit()
	state_machine.change_state_to("IDLE")

func stop()->void:
	stop_movement = true

func exit_state()->void:
	state_machine.user.stop_move_order.disconnect(stop)
