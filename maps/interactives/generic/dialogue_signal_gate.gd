extends SignalGate
class_name DialogueSignalGate

@export var dialogic_var: String

func setup_extra()->void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = 64*Vector2(float(dimensions.x)/scale.x, float(dimensions.y)/scale.y)
	if cur_state != state.open:
		collision.shape = shape
		sprite.texture = locked_texture
		if cur_state == state.locked:
			Dialogic.VAR.set(dialogic_var, signal_index)
	if !Dialogic.signal_event.is_connected(advance_unlock):
		Dialogic.signal_event.connect(advance_unlock)
	_calc_occupied()

func _interacted(_character: Character):
	if cur_state == state.locked:
		audio.play()
		if dialogue_timeline != null:
			EventBus.broadcast("ENTER_DIALOGUE", [dialogue_timeline, false])
		interacted.emit()
	elif cur_state == state.unlocked:
		open()

func advance_unlock(signal_event: String)->void:
	if !signal_event in signals_needed:
		return
	if !signal_index>=signals_needed.size():
		if signal_event==signals_needed[signal_index]:
			signal_index += 1
			Dialogic.VAR.set(dialogic_var, signal_index)
			if signal_index>=signals_needed.size():
				cur_state = state.unlocked
				if auto_open:
					open()
		else:
			signal_index = 0
			Dialogic.VAR.set(dialogic_var, signal_index)
