extends Node2D
class_name CombatManager

var battle_queue: Array[Character] = []
var player_team: Array[Character] = []
var enemy_team: Array[Character] = []
var round_num: int = 1
signal round_start(battle_queue)
signal battle_end
signal run_round
signal turn_ended
signal continue_round(yes: bool)

func _ready()->void:
	run_round.connect(start_round)

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
	GlobalRes.print_log("Round "+str(round_num))
	round_num += 1
	for character in battle_queue:
		character.roll_sequence()
	battle_queue.sort_custom(func(a,b): return a.sequence<b.sequence)
	round_start.emit(battle_queue)
	for character in battle_queue:
		character.taking_turn = true
		character.damage_reduction = 0
		if character.has_method("take_turn"):
			character.call_deferred("take_turn")
		character.ended_turn.connect(end_turn)
		if !await continue_round:
			return
	run_round.emit()

func end_turn(character: Character)->void:
	turn_ended.emit()
	character.ended_turn.disconnect(end_turn)
	character.taking_turn = false
	character.refresh()
	if enemy_team.size() == 0 || player_team.size() == 0:
		call_deferred("end_combat")
		continue_round.emit(false)
	else:
		continue_round.emit(true)

func end_combat()->void:
	round_num = 1
	GlobalRes.timer.start()
	for character in battle_queue:
		character.defeated.disconnect(char_defeated)
		character.in_combat = false
		character.taking_turn = false
	battle_queue = []
	battle_end.emit()
