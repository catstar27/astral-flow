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
	if abs(cur_target - state_machine.user.position).x <= (Vector2.ONE*Settings.tile_size).x:
		if abs(cur_target - state_machine.user.position).y <= (Vector2.ONE*Settings.tile_size).y:
			if abs(cur_target - state_machine.user.position) != Vector2.ONE*Settings.tile_size:
				if NavMaster.is_pos_occupied(cur_target):
					return true
	var path: Array[Vector2] = NavMaster.request_nav_path(state_machine.user.position, cur_target)
	if path.pop_front() != state_machine.user.position:
		path = []
	for pos in path:
		if NavMaster.is_pos_occupied(pos):
			path = NavMaster.request_nav_path(state_machine.user.position, cur_target)
			path.pop_front()
			continue
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
		state_machine.user.pos_changed.emit(state_machine.user)
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
