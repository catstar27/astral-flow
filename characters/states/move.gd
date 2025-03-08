extends State
## State that moves a character to a given position

var stop_movement: bool = false ## At each step, determines whether to stop movement or not
var target: Vector2 ## Position this is trying to move the user to

func enter_state(data: Vector2, _data2 = null)->void:
	stop_movement = false
	state_machine.user.move_order.connect(new_move_order)
	state_machine.user.stop_move_order.connect(stop)
	target = data
	var end: bool = false
	while !end:
		end = await move(target)
		state_machine.user.anim_player.play("RESET")
	state_machine.change_state_to("IDLE")

## Handles actual movement. Returns true if the user reached the destination,
## or if they should stop attempting to move. 
func move(cur_target: Vector2)->bool:
	if cur_target == state_machine.user.position:
		return true
	# Prevents calculating a path when the user is adjacent to the target position and the position is occupied
	if abs(cur_target - state_machine.user.position).x <= (Vector2.ONE*NavMaster.tile_size).x:
		if abs(cur_target - state_machine.user.position).y <= (Vector2.ONE*NavMaster.tile_size).y:
			if abs(cur_target - state_machine.user.position) != Vector2.ONE*NavMaster.tile_size:
				if NavMaster.is_pos_occupied(cur_target):
					return true
	var path: Array[Vector2] = NavMaster.request_nav_path(state_machine.user.position, cur_target)
	var prev_direction: Vector2 = Vector2.ZERO
	if path.pop_front() != state_machine.user.position:
		path = []
	for pos in path:
		if NavMaster.is_pos_occupied(pos):
			path = NavMaster.request_nav_path(state_machine.user.position, cur_target)
			path.pop_front()
			continue
		if state_machine.user.cur_ap == 0:
			EventBus.broadcast("PRINT_LOG","No ap for movement!")
			return true
		if stop_movement:
			return true
		if target != cur_target:
			return false
		var prev_pos: Vector2 = state_machine.user.position
		var direction: Vector2 = pos-prev_pos
		if direction.length() > NavMaster.tile_size:
			continue
		EventBus.broadcast("TILE_OCCUPIED", pos)
		if direction != prev_direction || !state_machine.user.anim_player.is_playing():
			if direction == Vector2.UP*64:
				state_machine.user.anim_player.play("Character/walk_up")
			elif direction == Vector2.DOWN*64:
				state_machine.user.anim_player.play("Character/walk_down")
			elif direction == Vector2.RIGHT*64:
				state_machine.user.anim_player.play("Character/walk_right")
			elif direction == Vector2.LEFT*64:
				state_machine.user.anim_player.play("Character/walk_left")
		prev_direction = direction
		while paused:
			await state_unpaused
		critical_entered.emit()
		critical_operation = true
		await create_tween().tween_property(state_machine.user, "position", pos, .25).finished
		EventBus.broadcast("TILE_UNOCCUPIED", prev_pos)
		state_machine.user.pos_changed.emit(state_machine.user)
		critical_operation = false
		critical_exited.emit()
		if state_machine.user.in_combat:
			state_machine.user.cur_ap -= 1
			state_machine.user.stats_changed.emit()
	return true

## Updates the target position with a new one
func new_move_order(pos: Vector2)->void:
	target = pos

## Sets stop_movement, which will end the current movement before the next tween
func stop()->void:
	stop_movement = true

func exit_state()->void:
	state_machine.user.move_order.disconnect(new_move_order)
	state_machine.user.stop_move_order.disconnect(stop)
