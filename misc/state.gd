extends Node
class_name State

@export var state_id: String
@export var state_machine: StateMachine
var paused: bool = false
var critical_operation: bool = false
@warning_ignore("unused_signal") signal change_state(state)
@warning_ignore("unused_signal") signal state_paused
@warning_ignore("unused_signal") signal state_unpaused
@warning_ignore("unused_signal") signal critical_entered
@warning_ignore("unused_signal") signal critical_exited

func enter_state(_data)->void:
	return

func process_state(_delta: float)->void:
	return

func physics_process_state(_delta: float)->void:
	return

func exit_state()->void:
	return
