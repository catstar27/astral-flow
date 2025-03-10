extends Task
class_name InteractTask
## Task that makes the user interact with an object at target location
##
## Has an option to allow the user to shove characters in the way

@export var interact_pos: Vector2 ## Position to interact with object

func task()->void:
	await interact()

## Attempts to interact with an object at the target position
func interact()->void:
	var attempts: int = 0
	var can_interact: bool = (abs(user.position - interact_pos).x+abs(user.position - interact_pos).y)/NavMaster.tile_size <= 1
	while !can_interact:
		if user.in_combat:
			return
		user.move_order.emit(interact_pos)
		while paused:
			await unpause
		while user.state_machine.current_state.state_id != "IDLE":
			await user.state_machine.state_changed
		can_interact = (abs(user.position - interact_pos).x+abs(user.position - interact_pos).y)/NavMaster.tile_size <= 1
		attempts += 1
		if attempts > 99:
			return
	if can_interact:
		while paused:
			await unpause
		user.interact_order.emit(NavMaster.get_obj_at_pos(interact_pos))
		while user.state_machine.current_state.state_id != "IDLE":
			await user.state_machine.state_changed
