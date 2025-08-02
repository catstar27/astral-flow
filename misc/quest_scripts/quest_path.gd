extends Resource
class_name QuestPath
## Intermediate between QuestInfo and QuestStage, allowing alternate stages to be completed

@export var id: String ## ID of this quest path
@export var path_stages: Array[QuestStage] ## QuestStages in this QuestPath
var current_stage: int = 0 ## Current stage active in this path

func _to_string() -> String:
	return "QuestPath:'"+id+"'<"+str(path_stages)+">"

## Gets stages to display in this quest path
func get_path_stages()->Array[QuestStage]:
	var arr: Array[QuestStage]
	var end_stage: int = current_stage
	var start_stage: int = current_stage
	while path_stages[start_stage].show_prev_stage && start_stage > 0:
		start_stage -= 1
	for index in range(start_stage, end_stage+1):
		arr.append(path_stages[index])
	return arr

## Duplicates this quest path
func duplicate_path()->QuestPath:
	var clone: QuestPath = duplicate(true)
	clone.path_stages.clear()
	for stage in path_stages:
		clone.path_stages.append(stage.duplicate_stage())
	return clone

## Checks if this path is complete
func is_path_complete()->bool:
	for stage in path_stages:
		if !stage.complete:
			return false
	return true
