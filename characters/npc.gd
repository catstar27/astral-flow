extends Character
class_name NPC

@export var dialogue: String
var dialogue_timeline: DialogicTimeline = null

func _ready()->void:
	_setup()

func _interacted(_interactor: Character)->void:
	return
