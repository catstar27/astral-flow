extends State
## State that activates an ability

@export var sound: AudioStreamWAV ## Sound to play when attempting to use ability on invalid position

func enter_state(ability: Ability, destination: Vector2)->void:
	if !ability.is_tile_valid(destination):
		EventBus.broadcast("PLAY_SOUND", [sound, "positional", state_machine.user.global_position])
		state_machine.change_state_to("IDLE")
		return
	if ability.ap_cost>state_machine.user.cur_ap:
		EventBus.broadcast("PRINT_LOG","Not enough ap")
		state_machine.change_state_to("IDLE")
		return
	if ability.mp_cost>state_machine.user.cur_mp:
		EventBus.broadcast("PRINT_LOG","Not enough mp")
		state_machine.change_state_to("IDLE")
		return
	critical_entered.emit()
	critical_operation = true
	var prev_ability: Ability = state_machine.user.selected_ability
	state_machine.user.call_deferred("deselect_ability", true)
	state_machine.user.cur_ap -= ability.ap_cost
	state_machine.user.cur_mp -= ability.mp_cost
	state_machine.user.stats_changed.emit()
	await ability.activate(destination)
	critical_operation = false
	critical_exited.emit()
	if state_machine.user.selected_ability == null && prev_ability == ability && state_machine.user.is_selected:
		state_machine.user.call_deferred("select_ability", ability)
	state_machine.change_state_to("IDLE")
