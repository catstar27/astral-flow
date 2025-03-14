extends Task
class_name MoveTask
## Task that makes the user move to a target location
##
## Has an option to allow the user to shove characters in the way

@export var move_location: Vector2 ## Location to move to

func task()->void:
	await move()

## Attempts to move to the location
func move()->void:
	var attempts: int = 0
	while user.position != move_location:
		if user.in_combat:
			return
		user.move_order.emit(move_location)
		while paused:
			await unpause
		while user.state_machine.current_state.state_id != "IDLE":
			await user.state_machine.state_changed
		if user.position != move_location:
			await user.get_tree().create_timer(.5).timeout
		attempts += 1
		if attempts > 99:
			return
