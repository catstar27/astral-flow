extends State

var stop_movement: bool = false
var target: Vector2

func enter_state(data: Vector2)->void:
	stop_movement = false
	state_machine.user.move_order.connect(new_move_order)
	state_machine.user.stop_move_order.connect(stop)
	target = data
	var end: bool = false
	while !end:
		end = await move(target)
	state_machine.change_state_to("IDLE")

func move(cur_target: Vector2)->bool:
	if cur_target == state_machine.user.position:
		return true
	var path: Array[Vector2] = NavMaster.request_nav_path(state_machine.user.position, cur_target)
	if path.pop_front() != state_machine.user.position:
		path = []
	for pos in path:
		if state_machine.user.cur_ap == 0:
			EventBus.broadcast(EventBus.Event.new("PRINT_LOG","No ap for movement!"))
			return true
		if stop_movement:
			return true
		if target != cur_target:
			return false
		var prev_pos: Vector2 = state_machine.user.position
		EventBus.broadcast(EventBus.Event.new("TILE_OCCUPIED", pos))
		await create_tween().tween_property(state_machine.user, "position", pos, .2).finished
		EventBus.broadcast(EventBus.Event.new("TILE_UNOCCUPIED", prev_pos))
		if state_machine.user.in_combat:
			state_machine.user.cur_ap -= 1
			state_machine.user.stats_changed.emit()
	return true

func new_move_order(pos: Vector2)->void:
	target = pos

func stop()->void:
	stop_movement = true

func exit_state()->void:
	state_machine.user.move_order.disconnect(new_move_order)
	state_machine.user.stop_move_order.disconnect(stop)
