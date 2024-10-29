extends Node2D
class_name CombatManager

var battle_queue: Array[Character] = []
var player_team: Array[Character] = []
var enemy_team: Array[Character] = []
signal round_start(battle_queue)
signal battle_end
signal run_round
signal turn_ended

func _ready()->void:
	run_round.connect(start_round)

func char_defeated(character: Character)->void:
	if character is Player:
		player_team.remove_at(player_team.find(character))
	if character is Enemy:
		enemy_team.remove_at(enemy_team.find(character))
	battle_queue.remove_at(battle_queue.find(character))
	character.defeated.disconnect(char_defeated)

func start_combat(participants: Array[Character])->void:
	GlobalRes.timer.stop()
	battle_queue = participants
	GlobalRes.selection_cursor.deselect()
	for character in participants:
		character.in_combat = true
		character.taking_turn = false
		if character.moving:
			character.stop_move = true
		character.refresh()
		character.defeated.connect(char_defeated)
		if character is Player:
			player_team.append(character)
		if character is Enemy:
			enemy_team.append(character)
	run_round.emit()

func start_round()->void:
	if enemy_team.size() == 0 || player_team.size() == 0:
		end_combat()
		return
	for character in battle_queue:
		character.roll_sequence()
	battle_queue.sort_custom(func(a,b): return a.sequence<b.sequence)
	round_start.emit(battle_queue)
	for character in battle_queue:
		character.taking_turn = true
		if character.has_method("take_turn"):
			character.call_deferred("take_turn")
		await character.ended_turn
		turn_ended.emit()
		character.taking_turn = false
		character.refresh()
	run_round.emit()

func end_combat()->void:
	GlobalRes.timer.start()
	for character in battle_queue:
		character.defeated.disconnect(char_defeated)
		character.in_combat = false
	battle_queue = []
	battle_end.emit()
