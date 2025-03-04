extends Character
class_name NPC
## Class for a basic NPC that triggers dialogue when interacted with

@export var dialogue: DialogicTimeline ## Dialogue for the NPC to enter when interacted

func _ready()->void:
	_setup()

## Called when interacted with
func _interacted(interactor: Character)->void:
	if dialogue != null && interactor is Player:
		EventBus.broadcast("ENTER_DIALOGUE", [dialogue, true])
