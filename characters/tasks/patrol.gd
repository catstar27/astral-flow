extends NPCTask
class_name PatrolTask
## Task that makes the user move between an array of positions
##
## Has an option to allow the user to shove characters in the way

@export var patrol_points: Array[Vector2] = [] ## Locations to patrol between

func task()->void:
	await patrol()

func patrol()->void:
	for pos in patrol_points:
		if user.in_combat:
			return
		while user.position != pos:
			if user.in_combat:
				return
			user.move_order.emit(pos)
			while paused:
				await unpause
			while user.state_machine.current_state.state_id != "IDLE":
				await user.state_machine.state_changed
