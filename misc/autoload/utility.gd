extends Node

class Status:
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
	var damage: int = 0
	enum time_options {constant, timed, instant}
	var time_choice: time_options = time_options.timed
	var duration: int = 1
	var stacking: bool = false
	var stacks: int = 1
	var action: Callable
	var action_args: Array
	var status_color: Color = Color.WHITE
	var id: String = "EMPTY_STATUS"
	var display_name: String = "Empty Status"
	func _to_string() -> String:
		return "Status<"+id+">"
