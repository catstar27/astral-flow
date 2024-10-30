extends Character
class_name Player

@onready var zap_scn: PackedScene = preload("res://characters/abilities/zap.tscn")
var selected_ability: Ability = null

func _ready() -> void:
	_setup()
	Dialogic.signal_event.connect(dialogue_signal_processor)

func dialogue_signal_processor(sig: String)->void:
	if sig == "test_room_zap_learned":
		add_ability(zap_scn)

func select_ability(ability: Ability)->void:
	selected_ability = ability
	place_range_indicators(ability.get_valid_destinations())

func deselect_ability()->void:
	selected_ability = null
	remove_range_indicators()

func after_ability()->void:
	if selected_ability != null:
		place_range_indicators(selected_ability.get_valid_destinations())
