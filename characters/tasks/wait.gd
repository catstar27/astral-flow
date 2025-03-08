extends NPCTask
class_name WaitTask
## Makes the user wait and do nothing for a set time

@export_range(0,10) var wait_time: float = 0.0 ## Time for user to wait

func task()->void:
	await wait()

## Waits the set time
func wait()->void:
	while user.state_machine.current_state.state_id != "IDLE":
		await user.state_machine.state_changed
	await user.get_tree().create_timer(wait_time).timeout
