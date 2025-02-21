extends Node
class_name StateMachine

@export var user: Node
@export var start_state_id: String
var state_dict: Dictionary = {}
var current_state: State = null
var paused: bool = false
signal state_changed(state: State)

func _ready()->void:
	for child in get_children():
		if child is State:
			state_dict[child.state_id] = child
	change_state_to(start_state_id)

func change_state_to(id: String, data = null)->void:
	if paused:
		return
	if state_dict[id] == null:
		printerr("Attempted to change to invalid state "+id)
		return
	if current_state != null:
		current_state.exit_state()
	current_state = state_dict[id]
	current_state.enter_state(data)
	state_changed.emit(current_state)

func _physics_process(delta: float) -> void:
	if current_state != null && !paused:
		current_state.physics_process_state(delta)

func _process(delta: float) -> void:
	if current_state != null && !paused:
		current_state.process_state(delta)

func pause()->void:
	current_state.paused = true
	current_state.state_paused.emit()
	paused = true

func unpause()->void:
	current_state.paused = false
	current_state.state_unpaused.emit()
	paused = false
