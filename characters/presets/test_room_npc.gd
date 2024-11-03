extends NPC

signal combat_gate_open

func _ready()->void:
	_setup()
	target_position = Vector2(32, -544)
	move_order.emit()
	await move_finished
	combat_gate_open.emit()
	target_position = Vector2(288, -736)
	move_order.emit()
	if dialogue != "":
		dialogue_timeline = load(dialogue)

func _interacted(_interactor: Character)->void:
	if dialogue_timeline != null:
		EventBus.broadcast(EventBus.Event.new("ENTER_DIALOGUE", dialogue_timeline))
