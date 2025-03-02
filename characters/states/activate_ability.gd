extends State

@export var sound: AudioStreamWAV

func enter_state(data: Array)->void:
	var ability: Ability = data[0]
	var destination: Vector2 = data[1]
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
	state_machine.user.anim_player.play("Character/melee")
	await state_machine.user.anim_activate_ability
	ability.call_deferred("activate", destination)
	await state_machine.user.anim_player.animation_finished
	critical_operation = false
	critical_exited.emit()
	if state_machine.user.selected_ability == null && prev_ability == ability:
		state_machine.user.call_deferred("select_ability", ability)
	state_machine.change_state_to("IDLE")
