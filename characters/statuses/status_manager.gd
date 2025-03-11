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
var processing_conditionals: bool = false ## Whether conditional statuses are being processed currently
signal status_damage_ticked(amount: int) ## Statuses applied this amount of total damage
signal status_stat_mod_changed(stat_mod: String, amount: int) ## The modification to stats has changed
signal status_action_occurred(action: Callable, args: Array) ## A status has attempted to call a callable
signal conditionals_processed ## Emitted when done processing conditional statuses
#endregion

#region Status Management
## Adds a status to the list of active statuses and begins calculating its effects
func add_status(status: Status, source: Node)->void:
	status.user = get_parent()
	status.source = source
	if status.time_choice == status.time_options.instant:
		var action: Callable = status.get_status_action()
		var action_args: Array = status.get_status_action_args().duplicate()
		status_action_occurred.emit(action, action_args)
		return
	var duplicate_status: Status = get_matching_status(status.id)
	if duplicate_status != null && !status.stacking:
		duplicate_status.duration = status.duration
		return
	elif duplicate_status != null && status.stacking:
		status_list[duplicate_status] += status.stacks
		duplicate_status.duration = status.duration
	else:
		status_list[status] = status.stacks
	if status.condition == status.condition_options.none:
		for stat in status.stat_mods:
			stat_mods[stat] += status.stat_mods[stat]
			status_stat_mod_changed.emit(stat, status.stat_mods[stat])
		damage += status.damage

## Ticks the statuses, dealing their damage and reducing duration
func tick_status()->void:
	if damage != 0:
		status_damage_ticked.emit(damage)
	for status in status_list.keys():
		if status.time_choice == status.time_options.timed:
			status.duration -= 1
			if status.duration == 0:
				remove_status(status)

## Removes modifications from a given status
func remove_status_mod(status: Status)->void:
	for stat in status.stat_mods:
		stat_mods[stat] -= status.stat_mods[stat]
		status_stat_mod_changed.emit(stat, -status.stat_mods[stat])
	damage -= status.damage

## Removes a status from the list
func remove_status(status: Status, remove_all_stacks: bool = false)->void:
	remove_status_mod(status)
	if status.stacking:
		status_list[status] -= 1
		if remove_all_stacks:
			while status_list[status] > 0:
				remove_status_mod(status)
				status_list[status] -= 1
		if status_list[status] == 0:
			status_list.erase(status)
	else:
		status_list.erase(status)

## Removes all statuses
func remove_all_statuses()->void:
	for status in status_list.keys():
		remove_status(status, true)

## Returns a status in the current list matching given id, or null if there is none
func get_matching_status(id: String)->Status:
	for status in status_list.keys():
		if status.id == id:
			return status
	return null
#endregion

#region Process Clear Condition Signals
## Clears statuses that end on movement
func process_move(_pos)->void:
	for status in status_list.keys():
		if status.clear_conditions.move:
			remove_status(status)

## Clears statuses that end on rest
func process_rest()->void:
	for status in status_list.keys():
		if status.clear_conditions.rest:
			remove_status(status)

## Clears statuses that end on taking damage
func process_damage(source: Node)->void:
	if source == self:
		return
	for status in status_list.keys():
		if status.clear_conditions.take_damage:
			remove_status(status)
#endregion

#region Conditional Triggers
## Triggers on_death condition statuses
func trigger_on_death()->void:
	processing_conditionals = true
	for status in status_list.keys():
		if status.condition == status.condition_options.on_death:
			if status.get_status_action() != status.get("empty_action"):
				var action: Callable = status.get_status_action()
				var action_args: Array = status.get_status_action_args().duplicate()
				status_action_occurred.emit(action, action_args)
			else:
				for stat in status.stat_mods:
					stat_mods[stat] += status.stat_mods[stat]
					status_stat_mod_changed.emit(stat, status.stat_mods[stat])
				damage += status.damage
			if status.time_choice == status.time_options.timed:
				remove_status(status)
	processing_conditionals = false
	conditionals_processed.emit()
#endregion

#region Save and Load
## Saves this status manager's statuses to the given file
func save_data(file: FileAccess)->void:
	for status in status_list.keys():
		if status.resource_path != "":
			file.store_var(status.resource_path)
			file.store_var(status_list[status])
	file.store_var("STATUS_MANAGER_END")

## Loads this status manager's statuses from the given file
func load_data(file: FileAccess)->void:
	var target: String = file.get_var()
	while target != "STATUS_MANAGER_END":
		var stacks: int = file.get_var()
		for num in range(0, stacks):
			var new_status: Status = load(target)
			var matching_status: Status = get_matching_status(new_status.id)
			if matching_status == null || status_list[matching_status] < stacks:
				add_status(new_status, get_parent())
		target = file.get_var()
#endregion
