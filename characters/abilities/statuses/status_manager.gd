extends Node
class_name StatusManager
## Manages statuses applied on the parent entity
##
## Contains all methods necessary to interface status effects with characters

#region Variables and Signals
var stat_mods: Dictionary = { ## Current total stat modification from statuses
	"max_ap": 0,
	"max_mp": 0,
	"max_hp": 0,
	"avoidance": 0,
	"crit_range": 0,
	"defense": 0,
	"damage_threshold": 0,
	"sequence": 0
}
var status_list: Dictionary[Status, int] ## Current active statuses and their stacks
var damage: int = 0 ## Total damage dealt per tick by statuses
signal status_damage_ticked(amount: int) ## Statuses applied this amount of total damage
signal status_stat_mod_changed(stat_mod: String, amount: int) ## The modification to stats has changed
signal status_action_occurred(action: Callable, args: Array) ## A status has attempted to call a callable
#endregion

#region Status Management
## Adds a status to the list of active statuses and begins calculating its effects
func add_status(status: Status, source: Node)->void:
	status.source = source
	if status.time_choice == status.time_options.instant:
		status_action_occurred.emit(status.action, status.action_args)
		return
	var duplicate_status: Status = get_matching_status(status.id)
	if duplicate_status != null && !status.stacking:
		duplicate_status.duration = status.duration
		return
	if duplicate_status != null && status.stacking:
		status_list[duplicate_status] += status.stacks
		duplicate_status.duration = status.duration
	else:
		status_list[status] = status.stacks
	for stat in status.stat_mods:
		stat_mods[stat] += status.stat_mods[stat]
		status_stat_mod_changed.emit(stat, status.stat_mods[stat])
	damage += status.damage

## Ticks the statuses, dealing their damage and reducing duration
func tick_status()->void:
	if damage != 0:
		status_damage_ticked.emit(damage)
	for status in status_list:
		if status.time_choice == status.time_options.timed:
			status.duration -= 1
			if status.duration == 0:
				remove_status(status)

## Removes a status from the list
func remove_status(status: Status)->void:
	for stat in status.stat_mods:
		stat_mods[stat] -= status.stat_mods[stat]
		status_stat_mod_changed.emit(stat, -status.stat_mods[stat])
	damage -= status.damage
	if status.stacking:
		status_list[status] -= 1
		if status_list[status] == 0:
			status_list.erase(status)
	else:
		status_list.erase(status)

## Returns a status in the current list matching given id, or null if there is none
func get_matching_status(id: String)->Status:
	for status in status_list:
		if status.id == id:
			return status
	return null
#endregion

#region Process Clear Condition Signals
## Clears statuses that end on movement
func process_move(_pos)->void:
	for status in status_list:
		if status.clear_conditions.move:
			remove_status(status)

## Clears statuses that end on rest
func process_rest()->void:
	for status in status_list:
		if status.clear_conditions.rest:
			remove_status(status)

## Clears statuses that end on taking damage
func process_damage(source: Node)->void:
	if source == self:
		return
	for status in status_list:
		if status.clear_conditions.take_damage:
			remove_status(status)
#endregion
