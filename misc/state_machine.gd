extends Node
class_name StateMachine

@export var user: Node
var state_dict: Dictionary = {}
var current_state: State = null

func _ready()->void:
	for child in get_children():
		if child is State:
			state_dict[child.state_id] = child

func change_state_to(id: String)->void:
	if current_state != null:
		current_state.exit_state()
	current_state = state_dict[id]
	current_state.enter_state()

func _physics_process(delta: float) -> void:
	current_state.physics_process_state(delta)

func _process(delta: float) -> void:
	current_state.process_state(delta)
