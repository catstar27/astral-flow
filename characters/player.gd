extends Character
class_name Player

@onready var zap_scn: PackedScene = preload("res://characters/abilities/zap.tscn")

func _ready() -> void:
	_setup()
	Dialogic.signal_event.connect(dialogue_signal_processor)

func dialogue_signal_processor(sig: String)->void:
	if sig == "test_room_zap_learned":
		add_ability(zap_scn)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("clear"):
		if selected_ability != null:
			deselect_ability()
			get_viewport().set_input_as_handled()
