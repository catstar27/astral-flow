extends Resource
class_name StagePath
## Intermediate between QuestStage and QuestObjective, allowing alternate ways to complete a stage

@export var id: String ## ID of this stage path
@export var path_objectives: Array[QuestObjective]

func _to_string() -> String:
	return "StagePath:'"+id+"'<"+str(path_objectives)+">"

## Duplicates this quest path
func duplicate_path()->StagePath:
	var clone: StagePath = duplicate(true)
	clone.path_objectives.clear()
	for objective in path_objectives:
		clone.path_objectives.append(objective.duplicate(true))
	return clone

## Checks if this path is complete
func is_path_complete()->bool:
	for objective in path_objectives:
		if !objective.complete && !objective.is_optional:
			return false
	return true
