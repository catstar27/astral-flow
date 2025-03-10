extends Node
class_name CombatManager
## Manages combat by holding all participating characters and making them take their turns

var battle_queue: Array[Character] = [] ## Queue of all characters currently in combat
var player_team: Array[Character] = [] ## Array of characters on the player's team
var enemy_team: Array[Character] = [] ## Array of characters on the enemy's team
var defeated: Array[Character] ## Array of characters defeated in this combat
var round_num: int = 1 ## Current round number
signal round_ended ## Emitted when a round has ended
signal continue_round(yes: bool) ## Emitted when a character is defeated; Arg determines whether to continue combat
signal display_cycled ## Signal that allows waiting for the sequence display to update

func _ready()->void:
	round_ended.connect(start_round)
	EventBus.subscribe("START_COMBAT", self, "start_combat")
	EventBus.subscribe("SEQUENCE_DISPLAY_CYCLED", self, "sequence_display_done")

## Called when the sequence display cycles to emit the signal for it
func sequence_display_done()->void:
	display_cycled.emit()

#region Characters
## Called when a character in combat is defeated, removing them from combat.
## Additionally ends combat if all of a team is defeated.
func character_defeated(character: Character)->void:
	if character in player_team:
		player_team.remove_at(player_team.find(character))
		for enemy in enemy_team:
			enemy.enemies.remove_at(enemy.enemies.find(character))
	if character in enemy_team:
		enemy_team.remove_at(enemy_team.find(character))
		for enemy in player_team:
			enemy.enemies.remove_at(enemy.enemies.find(character))
	battle_queue.remove_at(battle_queue.find(character))
	character.defeated_node.disconnect(character_defeated)
	if enemy_team.size() == 0 || player_team.size() == 0:
		call_deferred("end_combat")
		continue_round.emit(false)

## Adds a character to combat, putting them in combat state and halting current activity
func add_to_combat(character: Character)->void:
	character.enter_combat()
	character.taking_turn = false
	character.stop_movement()
	character.defeated_node.connect(character_defeated)
	if !character.hostile_to_player:
		player_team.append(character)
	if character.hostile_to_player:
		enemy_team.append(character)
#endregion

#region Combat Initiation
## Determines which character has higher sequence of two.
## Ties go in favor of the player
func sequence_sort(character1: Character, character2: Character)->bool:
	if character1 is Player && character2 is not Player:
		return character1.sequence >= character2.sequence
	else:
		return character1.sequence > character2.sequence

## Merges two instances of combat; for when a character tries to start
## combat with a character that is already in combat or vice versa
func merge_combat(to_merge: Array[Character])->void:
	var merge_queue: Array[Character] = []
	for participant in to_merge:
		if participant not in battle_queue:
			participant.roll_sequence()
			merge_queue.append(participant)
	merge_queue.sort_custom(sequence_sort)
	battle_queue.append_array(merge_queue)
	for character in battle_queue:
		if character in player_team:
			character.enemies.append_array(enemy_team)
		else:
			character.enemies.append_array(player_team)
	EventBus.broadcast("SEQUENCE_UPDATED", battle_queue)
	await display_cycled

## Starts combat with the given list of participants
func start_combat(participants: Array[Character])->void:
	var will_merge: bool = false
	participants.append_array(participants[0].allies)
	participants.append_array(participants[1].allies)
	for participant in participants:
		if participant.in_combat:
			will_merge = true
			break
	for character in participants:
		if character not in battle_queue:
			add_to_combat(character)
	if will_merge:
		await merge_combat(participants)
	else:
		EventBus.broadcast("COMBAT_STARTED", "NULLDATA")
		battle_queue = participants
		for character in battle_queue:
			if character in player_team:
				character.enemies.append_array(enemy_team)
			else:
				character.enemies.append_array(player_team)
		await get_tree().create_timer(.2).timeout
		round_ended.emit()

## Ends the current combat, returning the characters involved to non combat states
func end_combat()->void:
	round_num = 1
	for character in battle_queue:
		character.defeated_node.disconnect(character_defeated)
		character.exit_combat()
		character.taking_turn = false
	battle_queue = []
	EventBus.broadcast("COMBAT_ENDED", "NULLDATA")
#endregion

#region Round Processing
## Begins a round of combat, determining turn order and running each character's turns
func start_round()->void:
	if enemy_team.size() == 0 || player_team.size() == 0:
		end_combat()
		return
	EventBus.broadcast("PRINT_LOG","Round "+str(round_num))
	round_num += 1
	for character in battle_queue:
		character.roll_sequence()
	battle_queue.sort_custom(sequence_sort)
	EventBus.broadcast("ROUND_STARTED", battle_queue)
	await display_cycled
	for character in battle_queue:
		await process_turn(character)
	round_ended.emit()

## Initiates a given character's turn
func process_turn(character: Character)->void:
	character.taking_turn = true
	character.refresh()
	character.ended_turn.connect(end_turn)
	character.call_deferred("take_turn")
	if !await continue_round:
		return

## Called when the current turn ends, determines whether to end combat
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
#endregion
