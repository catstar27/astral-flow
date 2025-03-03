extends Node
class_name State
## Base class for states, holding useful signals, variables, and methods

@export var state_id: String ## ID of the state
@export var state_machine: StateMachine ## State machine this is locked to
var paused: bool = false ## Whether the state is paused
var critical_operation: bool = false ## Whether this state is in a critical operation
@warning_ignore("unused_signal") signal change_state(state) ## Emitted to change states
@warning_ignore("unused_signal") signal state_paused ## Emitted when state pauses
@warning_ignore("unused_signal") signal state_unpaused ## Emitted when state unpauses
@warning_ignore("unused_signal") signal critical_entered ## Emitted when state starts critical operation
@warning_ignore("unused_signal") signal critical_exited ## Emitted when state finishes critical operation

## Called when the state is entered
func enter_state(_data)->void:
	return

## Called on every frame
func process_state(_delta: float)->void:
	return

## Called on every physics frame
func physics_process_state(_delta: float)->void:
	return

## Called when the state is exited
func exit_state()->void:
	return
