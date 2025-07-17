extends Resource
class_name Status
## The class for a status effect
##
## Can apply a variety of effects, 
## all of which are configured through exports

## Determines modifier applied to stats when this is active
@export var stat_mods: Dictionary[String, int] = {
	"max_ap": 0, ## Maximum Action Points
	"max_mp": 0, ## Maximum Magic Points
	"max_hp": 0, ## Maximum Health Points
	"avoidance": 0, ## Ability to Dodge
	"crit_range": 0, ## Ability to Crit
	"defense": 0, ## Reduces damage taken if below threshold
	"dt": 0, ## Threshold at which defense is no longer factored
	"sequence": 0, ## Likeliness of moving earlier in combat
	"move_speed": 0 ## Determines amount of tiles moved for each action point
}
## Conditions that cause the status to clear (or lose a stack)
@export var clear_conditions: Dictionary[String, bool] = {
	"take_damage": false, ## Affected entity takes damage
	"move": false, ## Affected entity moves
	"rest": false, ## Affected entity rests
	"triggered": false ## Status condition is triggered
}
@export var damage: int = 0 ## Damage dealt per status tick
@export_group("Time")
enum time_options { ## Options for how the status reacts to time
	constant, ## Status remains active regardless of time
	timed, ## Status is active for a set amount of time
	instant ## Status causes an effect and instantly ends
	} 
@export var time_choice: time_options = time_options.timed ## Selected time option
@export var duration: int = 1 ## Number of ticks this lasts for, if timed
@export_group("Stacking")
@export var stacking: bool = false ## Whether the status can stack with identical statuses
@export var stacks: int = 1 ## Number of stacks to be applied
@export_group("Conditional")
enum condition_options { ## Conditions for the status to trigger
	none, ## Status is not conditional
	on_death, ## Status triggeres upon death of the affected character
}
@export var condition: condition_options
@export_group("Code Execution")
@export var action_name: String ## Name of function to be called
var source: Node ## Source of the status
var user: Node ## Entity the status is affecting
@export_group("Display")
@export var status_color: Color = Color.WHITE ## Color of the status
@export var id: String = "EMPTY_STATUS" ## ID of the status, not displayed
@export var display_name: String = "Empty Status" ## Display name of status
@export var icon: Texture2D ## Icon for the status

func _to_string() -> String:
	return "Status<"+id+">"

## Sets the action for this status
func get_status_action()->Callable:
	if action_name != "" && get(action_name) != null:
		return get(action_name)
	return empty_action

## Sets the arguments for the status function stored here
func get_status_action_args()->Array:
	if get_status_action() == push:
		return [user, user.global_position-source.global_position]
	return []

## Used for incorrectly named status actions
func empty_action(_data: Array)->void:
	printerr("Attempted to run nonexistent status action: "+action_name)
	return

## Pushes a target
func push(data: Array)->void:
	if data == [] || data[0] == null:
		return
	var target: Node2D = data[0]
	var prev_pos: Vector2 = target.global_position
	var destination: Vector2 = target.global_position+data[1]
	var path: Array[Vector2] = NavMaster.request_nav_path(prev_pos, destination, false)
	path.pop_front()
	if path.size() == 1:
		EventBus.broadcast("TILE_OCCUPIED", [path.front(), target])
		await user.create_tween().tween_property(target, "position", path.front(), .1).finished
		EventBus.broadcast("TILE_UNOCCUPIED", prev_pos)

func full_heal(_data: Array)->void:
	if user is Character:
		user.cur_hp = user.base_stats.max_hp+user.stat_mods.max_hp
