extends NPC

func _ready()->void:
	_setup()
	target_position = Vector2(32, -544)
	move_order.emit()
	await move_finished
	GlobalRes.map.test_room_combat_gate.emit("test_room_combat_gate")
	target_position = Vector2(288, -736)
	move_order.emit()
	if dialogue != "":
		dialogue_timeline = load(dialogue)

func _interacted(_interactor: Character)->void:
	if dialogue_timeline != null:
		GlobalRes.current_timeline = Dialogic.start(dialogue_timeline)
