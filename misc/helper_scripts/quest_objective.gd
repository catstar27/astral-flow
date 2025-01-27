extends Node
class_name QuestObjective

@export var description: String
@export var event_id: String
@export var total_count: int
var current_count: int
var complete: bool = false
signal objective_completed(objective: QuestObjective)
signal objective_updated(objective: QuestObjective)

func update_objective(incoming_event_id: String)->void:
	if incoming_event_id != event_id:
		printerr("Attempted to update quest objective '"+description
		+"'with incorrect event '"+incoming_event_id+"'")
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
