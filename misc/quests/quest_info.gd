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
signal objective_updated(stage: QuestObjective) ## Emitted when an active objective is updated

## Activates this quest and its first stage
func activate()->void:
	active = true
	for stage in quest_stages:
		stage.stage_completed.connect(quest_stage_complete)
		stage.objective_updated.connect(update_quest)

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

## Called when an active objective updates, emitting the relevant signal
func update_quest(objective: QuestObjective)->void:
	objective_updated.emit(objective)

## Sets this quest to complete
func set_complete()->void:
	complete = true

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
