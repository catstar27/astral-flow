extends Resource
class_name QuestObjective
## Smallest level of quest; Represents a single objective
##
## Part of a quest stage, which is part of a quest
## When the objective receives a matching quest event,
## it updates. If it has a count greater than 0, it will
## automatically complete when the count reaches the max

@export var description: String ## Objective explanation that is displayed to player
@export var event_id: String ## ID of event that objective will await
@export var total_count: int ## Amount of times the quest objective needs to receive the signal
var current_count: int ## Number counting current progress towards this objective's completion
var complete: bool = false ## Whether this objective has been completed
signal objective_completed(objective: QuestObjective) ## Emitted when the objective is completed
signal objective_updated(objective: QuestObjective) ## Emitted when the objective's count updates

## Updates the objective when receiving the required quest event
func update_objective(incoming_event_id: String)->void:
	if incoming_event_id != event_id:
		printerr("Attempted to update quest objective '"+description
		+"' with incorrect event '"+incoming_event_id+"'")
		return
	if complete:
		return
	objective_updated.emit()
	if total_count == 0:
		objective_completed.emit(self)
		complete = true
	else:
		current_count += 1
		if current_count == total_count:
			objective_completed.emit(self)
			complete = true

## Saves the objective's current count
func save_data(file: FileAccess)->void:
	file.store_var(current_count)

## Loads the objective's current count
func load_data(file: FileAccess)->void:
	current_count = file.get_var()
