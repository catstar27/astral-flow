extends Node
class_name State

@export var state_id: String
@export var state_machine: StateMachine
@warning_ignore("unused_signal") signal change_state(state)

func enter_state()->void:
	return

func process_state(_delta: float)->void:
	return

func physics_process_state(_delta: float)->void:
	return

func exit_state()->void:
	return
