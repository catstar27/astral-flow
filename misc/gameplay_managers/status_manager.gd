extends Node
class_name StatusManager

var stat_mods: Dictionary = {
	"max_ap": 0,
	"max_mp": 0,
	"max_hp": 0,
	"avoidance": 0,
	"crit_range": 0,
	"defense": 0,
	"damage_threshold": 0,
	"sequence": 0
}
var status_list: Dictionary
var damage: int = 0
signal status_damage_ticked(amount: int)
signal status_stat_mod_changed(stat_mod: String, amount: int)
signal status_action_occurred(action: Callable, args: Array)

func add_status(status: Utility.Status)->void:
	if status.time_choice == status.time_options.instant:
		status_action_occurred.emit(status.action, status.action_args)
	elif status in status_list:
		if status.stacking:
			status_list[status] += status.stacks
			for stat in status.stat_mods:
				stat_mods[stat] += status.stat_mods[stat]
				status_stat_mod_changed.emit(stat, status.stat_mods[stat])
			damage += status.damage
	else:
		status_list[status] = status.stacks
		for stat in status.stat_mods:
			stat_mods[stat] += status.stat_mods[stat]
			status_stat_mod_changed.emit(stat, status.stat_mods[stat])
		damage += status.damage

func tick_status()->void:
	if damage != 0:
		status_damage_ticked.emit(damage)
	for status in status_list:
		if status.time_choice == status.time_options.timed:
			status.duration -= 1
			if status.duration == 0:
				remove_status(status)

func remove_status(status: Utility.Status)->void:
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
