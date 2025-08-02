extends Resource
class_name QuestStage
## Middle portion of a quest's composition
##
## Represents a stage of a quest, containing one or more objectives that can be progressed at the same time
## The stage is only complete when all objectives in it are complete.

## Dictionary of quest objectives held by this stage and their IDs
@export var show_prev_stage: bool = false ## Whether this stage should allow the previous stage to display
@export var stage_paths: Array[StagePath] ## List of stage paths in this stage
var active: bool = false ## Whether the stage (and its objectives) are active
var complete: bool = false ## Whether this stage is complete
var completed_path: StagePath ## The id of the path in this stage that was completed
signal stage_completed(stage: QuestStage) ## Emitted when the stage is completed
signal objective_updated(stage: QuestObjective) ## Emitted when an objective in the stage is updated
signal objective_completed(objective: QuestObjective) ## Emitted when an objective in the stage is completed

func _to_string() -> String:
	return "QuestStage<"+str(stage_paths)+">"

## Changes the stage to the active state and begins monitoring its objectives
func activate()->void:
	active = true
	for path in stage_paths:
		for objective in path.path_objectives:
			if !objective.objective_completed.is_connected(stage_objective_complete):
				objective.objective_completed.connect(stage_objective_complete)
			if !objective.objective_updated.is_connected(update_stage):
				objective.objective_updated.connect(update_stage)
			objective.check_completion()

## Called when an objective is complete. Updates the stage to reflect that
func stage_objective_complete(objective: QuestObjective)->void:
	if complete:
		return
	objective.objective_completed.disconnect(stage_objective_complete)
	objective.objective_updated.disconnect(update_stage)
	objective_completed.emit(objective)
	for path in stage_paths:
		if path.is_path_complete():
			complete = true
			completed_path = path
			stage_completed.emit(self)

## Checks if the stage is complete
func check_completion()->void:
	for path in stage_paths:
		for objective in path.path_objectives:
			objective.check_completion()

## Called when an objective in the stage updates, emitting the signal for it
func update_stage(objective: QuestObjective)->void:
	objective_updated.emit(objective)

## Returns all paths of the stage
func get_stage_paths()->Array[StagePath]:
	if complete:
		return [completed_path]
	var out: Array[StagePath]
	for path in stage_paths:
		out.append(path)
	return out

#region Save and Load
## Duplicates this quest stage and returns the duplicate
func duplicate_stage()->QuestStage:
	var new_stage: QuestStage = duplicate(true)
	new_stage.stage_paths.clear()
	for path in stage_paths:
		new_stage.stage_paths.append(path.duplicate_path())
	return new_stage

## Returns an array corresponding to completion of each objective
func get_save_data()->Array[Array]:
	var arr: Array[Array]
	var index: int = -1
	for path in stage_paths:
		arr.append([])
		index += 1
		for objective in path.path_objectives:
			arr[index].append(objective.current_count)
	return arr

## Loads the save data for each objective in this stage
func load_save_data(data: Array[Array])->void:
	var i: int = -1
	for path in data:
		i += 1
		var j: int = -1
		for count in data[i]:
			j += 1
			if i > stage_paths.size() || j > stage_paths[i].path_objectives.size():
				continue
			stage_paths[i].path_objectives[j].set_count(data[i][j])
#endregion
