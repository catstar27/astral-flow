extends Resource
class_name QuestObjective
## Smallest level of quest; Represents a single objective
##
## Part of a quest stage, which is part of a quest
## When the objective receives a matching quest event,
## it updates. If it has a count greater than 0, it will
## automatically complete when the count reaches the max

enum event_type_choices {
	open_door, ## Triggers when a door/gate is opened
	unlock_door, ## Triggers when a door/gate is unlocked
	trigger_switch, ## Triggers when a switch interactive is triggered
	interact_with, ## Triggers when an npc or interactive is interacted with
	defeat, ## Triggers when winning a battle with a character (or killing them)
	enter_map, ## Triggers when entering a map
	exit_map ## Triggers when exiting a map
}
@export var id: String ## ID of this objective
@export var description: String ## Objective explanation that is displayed to player
@export var event_type: event_type_choices ## Type of quest even to watch for
@export var event_emitter_name: String ## ID of node that triggers the objective
@export var total_count: int ## Amount of times the quest objective needs to receive the signal
@export var is_secret: bool = false ## Whether this objective should be shown in the tracker/log before completed
@export var is_optional: bool = false ## Whether this objective is needed to complete the stage
var current_count: int ## Number counting current progress towards this objective's completion
var complete: bool = false ## Whether this objective has been completed
signal objective_completed(objective: QuestObjective) ## Emitted when the objective is completed
signal objective_updated(objective: QuestObjective) ## Emitted when the objective's count updates

func _to_string() -> String:
	return id

## Checks if this objective is complete, and emits the signal if so
func check_completion()->void:
	if complete || current_count >= maxi(1, total_count):
		objective_completed.emit(self)

## Updates the objective when receiving the required quest event
func update_objective(incoming_event_id: String)->void:
	var event_id: String = event_type_choices.keys()[event_type]+":"+event_emitter_name
	if incoming_event_id != event_id:
		printerr("Attempted to update quest objective '"+description
		+"' with incorrect event '"+incoming_event_id+"'")
		return
	if complete:
		return
	objective_updated.emit(self)
	current_count += 1
	if current_count >= maxi(1, total_count):
		complete = true
		objective_completed.emit(self)

func set_count(count: int)->void:
	if count != current_count:
		objective_updated.emit(self)
	current_count = count
	if current_count >= maxi(1, total_count):
		complete = true
		objective_completed.emit(self)
