extends NPC

signal combat_gate_open

func _ready()->void:
	_setup()
	if dialogue != "":
		dialogue_timeline = load(dialogue)
	combat_gate_open.emit()
	move_order.emit(Vector2(32, -544))
	interact_order.emit(NavMaster.get_obj_at_pos(Vector2(32, -608)))
	await move_finished
	await get_tree().create_timer(.1).timeout
	interact_order.emit(NavMaster.get_obj_at_pos(Vector2(32, -608)))
	move_order.emit(Vector2(288, -736))

func _interacted(_interactor: Character)->void:
	if dialogue_timeline != null:
		EventBus.broadcast(EventBus.Event.new("ENTER_DIALOGUE", [dialogue_timeline, true]))
