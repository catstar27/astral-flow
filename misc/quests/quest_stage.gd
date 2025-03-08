extends Resource
class_name QuestStage
## Middle portion of a quest's composition
##
## Represents a stage of a quest, containing
## one or more objectives that can be progressed
## at the same time. The stage is only complete
## when all objectives in it are complete.

## Dictionary of quest objectives held by this stage and their IDs
@export var quest_objectives: Dictionary[String,QuestObjective]
var active: bool = false ## Whether the stage (and its objectives) are active
var objectives_complete: int = 0 ## Number of objectives that are currently complete
var complete: bool = false ## Whether this stage is complete
signal stage_completed(stage: QuestStage) ## Emitted when the stage is completed
signal objective_updated(stage: QuestObjective) ## Emitted when an objective in the stage is updated

## Changes the stage to the active state and begins monitoring its objectives
func activate()->void:
	active = true
	for id in quest_objectives:
		quest_objectives[id].objective_completed.connect(stage_objective_complete)
		quest_objectives[id].objective_updated.connect(update_stage)

## Called when an objective is complete. Updates the stage to reflect that
func stage_objective_complete(objective: QuestObjective)->void:
	objective.objective_completed.disconnect(stage_objective_complete)
	objective.objective_updated.disconnect(update_stage)
	objectives_complete += 1
	if objectives_complete == quest_objectives.size():
		complete = true
		stage_completed.emit(self)

## Called when an objective in the stage updates, emitting the signal for it
func update_stage(objective: QuestObjective)->void:
	objective_updated.emit(objective)

func get_stage_objectives()->Array[QuestObjective]:
	var out: Array[QuestObjective] = []
	for id in quest_objectives:
		out.append(quest_objectives[id])
	return out

## Saves the objectives in this stage and their ids
func save_data(file: FileAccess)->void:
	for id in quest_objectives:
		file.store_var(id)
		quest_objectives[id].save_data(file)
	file.store_var("END")

## Loads the stage's objectives
func load_data(file: FileAccess)->void:
	var id: String = file.get_var()
	while id != "END":
		if id not in quest_objectives:
			file.get_var()
		else:
			quest_objectives[id].load_data(file)
		id = file.get_var()
