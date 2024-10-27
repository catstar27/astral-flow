extends Node2D
class_name CombatManager

var battle_queue: Array[Character] = []
signal run_round

func _ready()->void:
	run_round.connect(start_round)

func start_combat(participants: Array[Character])->void:
	GlobalRes.timer.stop()
	battle_queue = participants
	for character in participants:
		character.in_combat = true
		character.stop_move = true
		character.refresh()

func start_round()->void:
	var seq_compare: Callable = (func(a,b): return a.sequence<b.sequence)
	for character in battle_queue:
		character.roll_sequence()
	battle_queue.sort_custom(seq_compare)
	for character in battle_queue:
		await character.end_turn
	run_round.emit()

func end_combat()->void:
	GlobalRes.timer.start()
	for character in battle_queue:
		character.in_combat = false
	battle_queue = []
