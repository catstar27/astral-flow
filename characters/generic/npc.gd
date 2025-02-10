extends Character
class_name NPC

@export var dialogue: DialogicTimeline

func _ready()->void:
	_setup()

func _interacted(_interactor: Character)->void:
	if dialogue != null:
		EventBus.broadcast("ENTER_DIALOGUE", [dialogue, true])
