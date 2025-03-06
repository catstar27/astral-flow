extends Node
class_name StateMachine
## Basic state machine class

@export var user: Node ## User of the state machine
@export var start_state_id: String ## ID of the starting state
var state_dict: Dictionary[String, State] = {} ## Dictionary of states and IDs
var current_state: State = null ## Currently selected state
var paused: bool = false ## Whether the state machine is paused
signal state_changed(state: State) ## Emitted when changing states

func _ready()->void:
	for child in get_children():
		if child is State:
			state_dict[child.state_id] = child
	change_state_to(start_state_id)

## Changes the state based on an id
func change_state_to(id: String, data = null, data2 = null)->void:
	if paused:
		return
	if state_dict[id] == null:
		printerr("Attempted to change to invalid state "+id)
		return
	if current_state != null:
		current_state.exit_state()
	current_state = state_dict[id]
	current_state.enter_state(data, data2)
	state_changed.emit(current_state)

func _physics_process(delta: float) -> void:
	if current_state != null && !paused:
		current_state.physics_process_state(delta)

func _process(delta: float) -> void:
	if current_state != null && !paused:
		current_state.process_state(delta)

## Pauses the machine
func pause()->void:
	current_state.paused = true
	current_state.state_paused.emit()
	paused = true

## Unpauses the machine
func unpause()->void:
	current_state.paused = false
	current_state.state_unpaused.emit()
	paused = false
