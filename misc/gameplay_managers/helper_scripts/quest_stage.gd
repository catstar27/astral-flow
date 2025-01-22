extends Node
class_name QuestStage

@export var quest_objectives: Array[QuestObjective]
var objectives_needed: int
var objectives_complete: int = 0
var complete: bool = false
signal stage_completed(stage: QuestStage)
signal objective_updated(stage: QuestObjective)

func _ready() -> void:
	objectives_needed = quest_objectives.size()
	for objective in quest_objectives:
		objective.objective_completed.connect(stage_objective_complete)
		objective.objective_updated.connect(update_stage)

func stage_objective_complete(objective: QuestObjective)->void:
	objective.objective_completed.disconnect(stage_objective_complete)
	objective.objective_updated.disconnect(update_stage)
	objectives_complete += 1
	if objectives_complete == objectives_needed:
		complete = true
		stage_completed.emit(self)

func update_stage(objective: QuestObjective)->void:
	objective_updated.emit(objective)
