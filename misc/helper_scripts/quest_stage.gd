extends Resource
class_name QuestStage

## Dictionary of quest objectives held by this stage and their IDs
@export var quest_objectives: Dictionary[String,QuestObjective]
var active: bool = false
var objectives_needed: int
var objectives_complete: int = 0
var complete: bool = false
signal stage_completed(stage: QuestStage)
signal objective_updated(stage: QuestObjective)

func activate()->void:
	active = true
	objectives_needed = quest_objectives.size()
	for id in quest_objectives:
		quest_objectives[id].objective_completed.connect(stage_objective_complete)
		quest_objectives[id].objective_updated.connect(update_stage)

func stage_objective_complete(objective: QuestObjective)->void:
	objective.objective_completed.disconnect(stage_objective_complete)
	objective.objective_updated.disconnect(update_stage)
	objectives_complete += 1
	if objectives_complete == objectives_needed:
		complete = true
		stage_completed.emit(self)

func update_stage(objective: QuestObjective)->void:
	objective_updated.emit(objective)

func get_stage_objectives()->Array[QuestObjective]:
	var out: Array[QuestObjective] = []
	for id in quest_objectives:
		out.append(quest_objectives[id])
	return out

func save_data(file: FileAccess)->void:
	for id in quest_objectives:
		file.store_var(id)
		quest_objectives[id].save_data(file)
	file.store_var("END")

func load_data(file: FileAccess)->void:
	var id: String = file.get_var()
	while id != "END":
		if id not in quest_objectives:
			file.get_var()
		else:
			quest_objectives[id].load_data(file)
		id = file.get_var()
