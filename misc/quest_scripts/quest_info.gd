extends Resource
class_name QuestInfo
## Main quest class; made up of stages
##
## Works much like quest stages, but instead
## of monitoring objectives, it monitors a list
## of quest stages. It also holds more general
## quest information such as name and id.

@export var quest_name: String ## Display name of the quest
@export var quest_id: String ## Internal name of the quest
@export var quest_description: String ## Description of the quest in journal
@export var quest_icon: Texture2D ## Icon of quest in journal
@export var quest_stages: Array[QuestStage] ## Array of stages in quest
var active: bool = false ## Whether the quest is active
var current_stage: int = 0 ## Current index of the quest stage
var complete: bool = false ## Whether the quest is complete
signal quest_complete(quest: QuestInfo) ## Emitted when the quest is completed
signal stage_started(stage: QuestStage) ## Emitted when the current stage is completed
signal objective_updated(objective: QuestObjective) ## Emitted when an active objective is updated
signal objective_completed(objective: QuestObjective) ## Emitted when an active objective is completed

## Activates this quest and its first stage
func activate()->void:
	active = true
	for stage in quest_stages:
		stage.stage_completed.connect(quest_stage_complete)
		stage.objective_updated.connect(update_quest)
	quest_stages[current_stage].activate()
	quest_stages[current_stage].check_completion()

## Gets the currently active quest stage
func get_current_stage()->QuestStage:
	return quest_stages[current_stage]

## Called when the current quest stage completes, moving the quest to the next stage
func quest_stage_complete(stage: QuestStage)->void:
	stage.stage_completed.disconnect(quest_stage_complete)
	stage.objective_updated.disconnect(update_quest)
	current_stage += 1
	if current_stage == quest_stages.size():
		complete = true
		quest_complete.emit(self)
	else:
		stage_started.emit(quest_stages[current_stage])
		quest_stages[current_stage].activate()

## Called when
func quest_objective_complete(objective: QuestObjective)->void:
	objective_completed.emit(objective)

## Called when an active objective updates, emitting the relevant signal
func update_quest(objective: QuestObjective)->void:
	objective_updated.emit(objective)

## Sets this quest to complete
func set_complete()->void:
	complete = true

## Gets a list of quest objectives that should be tracked
func get_tracked_objectives()->Array[QuestObjective]:
	var end_stage: int = current_stage
	var start_stage: int = current_stage
	while quest_stages[start_stage].show_prev_stage && start_stage > 0:
		start_stage -= 1
	var objectives: Array[QuestObjective] = []
	for index in range(start_stage, end_stage+1):
		objectives.append_array(quest_stages[index].get_stage_objectives())
	return objectives

#region Save and Load
## Duplicates this quest and returns the duplicate
func duplicate_quest()->QuestInfo:
	var new_quest: QuestInfo = duplicate(true)
	new_quest.quest_stages = []
	for stage in quest_stages:
		new_quest.quest_stages.append(stage.duplicate_stage())
	return new_quest

## Gets the save data for this quest
func get_save_data()->Array[Dictionary]:
	var arr: Array[Dictionary]
	for stage in quest_stages:
		arr.append(stage.get_save_data())
	return arr

## Loads the save data for this quest
func load_save_data(data: Array[Dictionary])->void:
	for index in range(0, quest_stages.size()):
		quest_stages[index].load_save_data(data[index])

## Saves the quest's data
func save_data(file: FileAccess)->void:
	for index in range(0, quest_stages.size()):
		file.store_var(str(index))
		quest_stages[index].save_data(file)
	file.store_var("END")

## Loads the quest's data
func load_data(file: FileAccess)->void:
	var index: String = file.get_var()
	while index != "END":
		if index.to_int() >= quest_stages.size():
			var dummy_stage: QuestStage = QuestStage.new()
			dummy_stage.load_data(file)
		else:
			quest_stages[index.to_int()].load_data(file)
		index = file.get_var()
#endregion
