extends Character
class_name Player

@onready var zap_scn: PackedScene = preload("res://characters/abilities/zap.tscn")

func _ready() -> void:
	_setup()
	Dialogic.signal_event.connect(dialogue_signal_processor)

func dialogue_signal_processor(sig: String)->void:
	if sig == "test_room_zap_learned":
		add_ability(zap_scn)

func end_turn()->void:
	if using_ability:
		await ability_used
	if state_machine.current_state.state_id == "MOVE":
		await move_finished
	ended_turn.emit(self)

func after_ability()->void:
	if selected_ability != null:
		place_range_indicators(selected_ability.get_valid_destinations(), selected_ability.target_type)
