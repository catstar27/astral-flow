extends Resource
class_name QuestObjective

@export var description: String ## Objective explanation that is displayed to player
@export var event_id: String ## ID of event that objective will await
@export var total_count: int ## Amount of times the quest objective needs to receive the signal
var current_count: int
var complete: bool = false
signal objective_completed(objective: QuestObjective)
signal objective_updated(objective: QuestObjective)

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

func save_data(file: FileAccess)->void:
	file.store_var(current_count)

func load_data(file: FileAccess)->void:
	current_count = file.get_var()
