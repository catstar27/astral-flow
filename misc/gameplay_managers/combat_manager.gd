extends Node
class_name CombatManager
## Manages combat by holding all participating characters

var battle_queue: Array[Character] = [] ## Queue of all characters currently in combat
var player_team: Array[Character] = [] ## Array of characters on the player's team
var enemy_team: Array[Character] = [] ## Array of characters on the enemy's team
var round_num: int = 1 ## Current round number
signal round_ended ## Emitted when a round has ended
## Emitted when a character is defeated; The argument determines whether to continue combat
signal continue_round(yes: bool)
signal display_cycled ## Signal that allows waiting for the sequence display to update

func _ready()->void:
	round_ended.connect(start_round)
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
	var merge_combat: bool = false
	participants.append_array(participants[0].allies)
	participants.append_array(participants[1].allies)
	for participant in participants:
		if participant.in_combat:
			merge_combat = true
			break
	for character in participants:
		if character not in battle_queue:
			character.enter_combat()
			character.taking_turn = false
			character.stop_movement()
			character.defeated.connect(char_defeated)
			if character is Player:
				player_team.append(character)
			if character is Enemy:
				enemy_team.append(character)
	if merge_combat:
		var merge_queue: Array[Character] = []
		for participant in participants:
			if participant not in battle_queue:
				participant.roll_sequence()
				merge_queue.append(participant)
		merge_queue.sort_custom(func(a,b): return a.sequence<b.sequence)
		battle_queue.append_array(merge_queue)
		EventBus.broadcast("SEQUENCE_UPDATED", battle_queue)
		await display_cycled
	else:
		EventBus.broadcast("COMBAT_STARTED", "NULLDATA")
		battle_queue = participants
		await get_tree().create_timer(.2).timeout
		round_ended.emit()

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
	await display_cycled
	for character in battle_queue:
		character.taking_turn = true
		character.refresh()
		character.stat_mods.lesser_dt = 0
		if character.has_method("take_turn"):
			character.call_deferred("take_turn")
		character.ended_turn.connect(end_turn)
		if !await continue_round:
			return
	round_ended.emit()

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
		character.exit_combat()
		character.taking_turn = false
	battle_queue = []
	EventBus.broadcast("COMBAT_ENDED", "NULLDATA")

func sequence_display_wait()->void:
	display_cycled.emit()
