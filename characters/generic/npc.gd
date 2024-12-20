extends Character
class_name NPC

@export var dialogue: DialogicTimeline

func _ready()->void:
	_setup()

func _interacted(_interactor: Character)->void:
	return
