extends Character
class_name Player

@onready var zap_scn: PackedScene = preload("res://characters/abilities/zap.tscn")

func _ready() -> void:
	_setup()
	Dialogic.signal_event.connect(dialogue_signal_processor)

func dialogue_signal_processor(sig: String)->void:
	if sig == "test_room_zap_learned":
		add_ability(zap_scn)
