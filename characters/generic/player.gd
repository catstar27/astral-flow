extends Character
class_name Player
## Class for the player

func _ready() -> void:
	_setup()
	Dialogic.signal_event.connect(dialogue_signal_processor)
	EventBus.broadcast("PARTY_CHANGED", "NULLDATA")

## Processes dialogue signals; possibly to be removed in the future
## Currently just here to add the zap ability
func dialogue_signal_processor(sig)->void:
	if sig is String && sig == "test_room_zap_learned":
		add_ability(load("res://characters/abilities/zap.tres"))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("clear"):
		if selected_ability != null:
			deselect_ability()
			get_viewport().set_input_as_handled()

func load_extra()->void:
	if Dialogic.VAR.get_variable("learned_zap"):
		dialogue_signal_processor("test_room_zap_learned")
