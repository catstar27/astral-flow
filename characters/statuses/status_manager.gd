extends Node
class_name StatusManager
## Manages statuses applied on the parent entity
##
## Contains all methods necessary to interface status effects with characters

#region Variables and Signals
var star_stat_mods: Dictionary[String, int] = { ## Stats modified on the stat star
	"intelligence": 0,
	"agility": 0,
	"strength": 0,
	"endurance": 0,
	"charisma": 0,
	"resolve": 0,
	"passion": 0
}
var stat_mods: Dictionary = { ## Current total stat modification from statuses
	"max_ap": 0,
	"max_mp": 0,
	"max_hp": 0,
	"avoidance": 0,
	"crit_range": 0,
	"defense": 0,
	"dt": 0,
	"sequence": 0,
	"move_speed": 0
}
var status_list: Dictionary[Status, Array] ## Current active statuses and an array holding duration and stacks respectively
var damage: int = 0 ## Total damage dealt per tick by statuses
var processing_conditionals: bool = false ## Whether conditional statuses are being processed currently
signal status_damage_ticked(amount: int) ## Statuses applied this amount of total damage
signal status_star_stat_mod_changed(stat_mod: String, amount: int) ## The modification to star stats has changed
signal status_stat_mod_changed(stat_mod: String, amount: int) ## The modification to stats has changed
signal status_action_occurred(action: Callable, args: Array) ## A status has attempted to call a callable
signal conditionals_processed ## Emitted when done processing conditional statuses
signal status_ticked ## Emitted when statuses are ticked
signal status_list_changed ## Emitted when the list of statuses changes
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
		status_list[duplicate_status][0] = status.duration
		return
	elif duplicate_status != null && status.stacking:
		status_list[duplicate_status][1] += status.stacks
		status_list[duplicate_status][0] = status.duration
	else:
		status_list[status] = [status.duration, status.stacks]
	if status.condition == status.condition_options.none:
		for stat in status.stat_mods:
			stat_mods[stat] += status.stat_mods[stat]
			status_stat_mod_changed.emit(stat, status.stat_mods[stat])
		damage += status.damage
	status_list_changed.emit()

## Ticks the statuses, dealing their damage and reducing duration
func tick_status()->void:
	if damage != 0:
		status_damage_ticked.emit(damage)
	for status in status_list.keys():
		if status.time_choice == status.time_options.timed:
			status_list[status][0] -= 1
			if status_list[status][0] == 0:
				remove_status(status)
	status_ticked.emit()

## Removes modifications from a given status
func remove_status_mod(status: Status)->void:
	for stat in star_stat_mods:
		star_stat_mods[stat] -= status.star_stat_mods[stat]
		status_star_stat_mod_changed.emit(stat, -status.star_stat_mods[stat])
	for stat in status.stat_mods:
		stat_mods[stat] -= status.stat_mods[stat]
		status_stat_mod_changed.emit(stat, -status.stat_mods[stat])
	damage -= status.damage

## Removes a status from the list
func remove_status(status: Status, remove_all_stacks: bool = false)->void:
	remove_status_mod(status)
	if status.stacking:
		status_list[status][1] -= 1
		if remove_all_stacks:
			while status_list[status][1] > 0:
				remove_status_mod(status)
				status_list[status][1] -= 1
		if status_list[status][1] == 0:
			status_list.erase(status)
	else:
		status_list.erase(status)
	status_list_changed.emit()

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
				for stat in status.star_stat_mods:
					star_stat_mods[stat] += status.star_stat_mods[stat]
					status_star_stat_mod_changed.emit(stat, status.star_stat_mods[stat])
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
## Gets a dictionary with saved values
func get_save_data()->Dictionary[String, Variant]:
	var dict: Dictionary[String, Variant]
	for status in status_list.keys():
		if status.resource_path != "":
			dict[status.resource_path] = status_list[status]
	return dict

## Loads the status effects from given data
func load_save_data(data: Dictionary[String, Variant])->void:
	for value in data:
		var stacks: int = data[value][1]
		for num in range(0, stacks):
			var new_status: Status = load(value)
			var matching_status: Status = get_matching_status(new_status.id)
			if matching_status == null || status_list[matching_status][1] < stacks:
				add_status(new_status, get_parent())
				matching_status = get_matching_status(new_status.id)
#endregion
