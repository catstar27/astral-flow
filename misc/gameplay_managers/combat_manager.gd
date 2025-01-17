extends Node2D
class_name CombatManager

var battle_queue: Array[Character] = []
var player_team: Array[Character] = []
var enemy_team: Array[Character] = []
var round_num: int = 1
signal run_round
signal continue_round(yes: bool)
signal display_cycled

func _ready()->void:
	run_round.connect(start_round)
	EventBus.subscribe("START_COMBAT", self, "start_combat")
	EventBus.subscribe("SEQUENCE_DISPLAY_CYCLED", self, "sequence_display_wait")

func new_combat_event(id: String)->EventBus.Event:
	return EventBus.Event.new(id, battle_queue)

func char_defeated(character: Character)->void:
	if character is Player:
		player_team.remove_at(player_team.find(character))
	if character is Enemy:
		enemy_team.remove_at(enemy_team.find(character))
	battle_queue.remove_at(battle_queue.find(character))
	character.defeated.disconnect(char_defeated)
	if enemy_team.size() == 0 || player_team.size() == 0:
		call_deferred("end_combat")
		continue_round.emit(false)

func start_combat(participants: Array[Character])->void:
	participants.append_array(participants[0].allies)
	participants.append_array(participants[1].allies)
	EventBus.broadcast("COMBAT_STARTED", "NULLDATA")
	battle_queue = participants
	for character in participants:
		character.combat_entered.emit()
		character.taking_turn = false
		character.stop_move_order.emit()
		character.defeated.connect(char_defeated)
		if character is Player:
			player_team.append(character)
		if character is Enemy:
			enemy_team.append(character)
	await get_tree().create_timer(.2).timeout
	run_round.emit()

func start_round()->void:
	if enemy_team.size() == 0 || player_team.size() == 0:
		end_combat()
		return
	EventBus.broadcast("PRINT_LOG","Round "+str(round_num))
	round_num += 1
	for character in battle_queue:
		character.roll_sequence()
	battle_queue.sort_custom(func(a,b): return a.sequence<b.sequence)
	EventBus.broadcast("ROUND_STARTED", battle_queue)
	for character in battle_queue:
		character.taking_turn = true
		character.refresh()
		character.stat_mods.lesser_dt = 0
		if character.has_method("take_turn"):
			character.call_deferred("take_turn")
		character.ended_turn.connect(end_turn)
		if !await continue_round:
			return
	run_round.emit()

func end_turn(character: Character)->void:
	EventBus.broadcast("TURN_ENDED", "NULLDATA")
	character.ended_turn.disconnect(end_turn)
	character.taking_turn = false
	if enemy_team.size() == 0 || player_team.size() == 0:
		call_deferred("end_combat")
		continue_round.emit(false)
	else:
		await display_cycled
		continue_round.emit(true)

func end_combat()->void:
	round_num = 1
	for character in battle_queue:
		character.defeated.disconnect(char_defeated)
		character.combat_exited.emit()
		character.taking_turn = false
	battle_queue = []
	EventBus.broadcast("COMBAT_ENDED", "NULLDATA")

func sequence_display_wait()->void:
	display_cycled.emit()
