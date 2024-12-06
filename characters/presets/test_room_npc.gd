extends NPC

var blocked_dialogue: String = "res://dialogue/test_room_npc_blocked.dtl"
signal combat_gate_open

func _ready()->void:
	_setup()
	if dialogue != "":
		dialogue_timeline = load(dialogue)
	combat_gate_open.emit()
	while position != Vector2(32, -544):
		if NavMaster.is_pos_occupied(Vector2(32, -544)):
			EventBus.broadcast(EventBus.Event.new("ENTER_DIALOGUE", [blocked_dialogue, true]))
			move_order.emit(Vector2(-32, -544))
			while state_machine.current_state.state_id != "IDLE":
				await state_machine.state_changed
			ability_order.emit([get_abilities()[0], Vector2(32, -544)])
			while state_machine.current_state.state_id != "IDLE":
				await state_machine.state_changed
		move_order.emit(Vector2(32, -544))
		while state_machine.current_state.state_id != "IDLE":
			await state_machine.state_changed
	interact_order.emit(NavMaster.get_obj_at_pos(Vector2(32, -608)))
	while state_machine.current_state.state_id != "IDLE":
		await state_machine.state_changed
	await get_tree().create_timer(.1).timeout
	move_order.emit(Vector2(288, -736))

func _interacted(_interactor: Character)->void:
	if dialogue_timeline != null:
		EventBus.broadcast(EventBus.Event.new("ENTER_DIALOGUE", [dialogue_timeline, true]))
