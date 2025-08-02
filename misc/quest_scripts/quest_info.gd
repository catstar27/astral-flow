extends Resource
class_name QuestInfo
## Main quest class; made up of stages
##
## Works much like quest stages, but instead of monitoring objectives, it monitors a list of quest stages
## It also holds more general quest information such as name and id.

@export var quest_name: String ## Display name of the quest
@export var quest_id: String ## Internal name of the quest
@export var quest_description: String ## Description of the quest in journal
@export var quest_icon: Texture2D ## Icon of quest in journal
@export var quest_paths: Array[QuestPath] ## Quest paths in quest
var active: bool = false ## Whether the quest is active
var complete_path: QuestPath ## The path that was completed in this quest
var complete: bool = false ## Whether the quest is complete
signal quest_complete(quest: QuestInfo) ## Emitted when the quest is completed
signal stage_started(stage: QuestStage) ## Emitted when the current stage is completed
signal objective_updated(objective: QuestObjective) ## Emitted when an active objective is updated
signal objective_completed(objective: QuestObjective) ## Emitted when an active objective is completed
signal path_updated(quest_path: QuestPath, completed_stage: QuestStage) ## Emitted when a stage completes

func  _to_string() -> String:
	return "QuestInfo:"+quest_id

## Activates this quest and its first stage
func activate()->void:
	active = true
	for path in quest_paths:
		for stage in path.path_stages:
			if !stage.stage_completed.is_connected(quest_stage_complete):
				stage.stage_completed.connect(quest_stage_complete)
			if !stage.objective_updated.is_connected(update_quest):
				stage.objective_updated.connect(update_quest)
		path.path_stages[path.current_stage].activate()
		path.path_stages[path.current_stage].check_completion()

## Gets the currently active quest stages
func get_current_stages()->Array[QuestStage]:
	var arr: Array[QuestStage]
	for path in quest_paths:
		arr.append(path.path_stages[path.current_stage])
	return arr

## Called when the current quest stage completes, moving the quest to the next stage
func quest_stage_complete(stage: QuestStage)->void:
	stage.stage_completed.disconnect(quest_stage_complete)
	stage.objective_updated.disconnect(update_quest)
	var cur_path: QuestPath = null
	var now_complete: bool = false
	for path in quest_paths:
		if stage == path.path_stages[path.current_stage]:
			if path.current_stage != path.path_stages.size()-1:
				path.current_stage += 1
			else:
				now_complete = true
			cur_path = path
			break
	if now_complete:
		complete = true
		complete_path = cur_path
		quest_complete.emit(self)
	else:
		stage_started.emit(cur_path.path_stages[cur_path.current_stage])
		cur_path.path_stages[cur_path.current_stage].activate()
	path_updated.emit(cur_path, stage)

## Called when
func quest_objective_complete(objective: QuestObjective)->void:
	objective_completed.emit(objective)

## Called when an active objective updates, emitting the relevant signal
func update_quest(objective: QuestObjective)->void:
	objective_updated.emit(objective)

## Sets this quest to complete
func set_complete()->void:
	complete = true

#region Save and Load
## Duplicates this quest and returns the duplicate
func duplicate_quest()->QuestInfo:
	var new_quest: QuestInfo = duplicate(true)
	new_quest.quest_paths.clear()
	for path in quest_paths:
		new_quest.quest_paths.append(path.duplicate_path())
	return new_quest

## Gets the save data for this quest
func get_save_data()->Array[Array]:
	var arr: Array[Array]
	var index: int = -1
	for path in quest_paths:
		arr.append([])
		index += 1
		for stage in path.path_stages:
			arr[index].append(stage.get_save_data())
	return arr

## Loads the save data for this quest
func load_save_data(data: Array[Array])->void:
	var i: int = -1
	for path in data:
		i += 1
		var j: int = -1
		for count in data[i]:
			j += 1
			if i > quest_paths.size() || j > quest_paths[i].path_stages.size():
				continue
			quest_paths[i].path_stages[j].load_save_data(data[i][j])
#endregion
