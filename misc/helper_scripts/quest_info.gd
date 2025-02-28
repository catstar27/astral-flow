extends Resource
class_name QuestInfo

@export var quest_name: String ## Display name of the quest
@export var quest_id: String ## Internal name of the quest
@export var quest_description: String ## Description of the quest in journal
@export var quest_icon: Texture2D ## Icon of quest in journal
@export var quest_stages: Array[QuestStage] ## Array of stages in quest
var active: bool = false
var stage_count: int
var current_stage: int = 0
var complete: bool = false
signal quest_complete(quest: QuestInfo)
signal objective_updated(stage: QuestObjective)

func activate()->void:
	active = true
	stage_count = quest_stages.size()
	for stage in quest_stages:
		stage.stage_completed.connect(quest_stage_complete)
		stage.objective_updated.connect(update_quest)

func get_current_stage()->QuestStage:
	return quest_stages[current_stage]

func quest_stage_complete(stage: QuestStage)->void:
	stage.stage_completed.disconnect(quest_stage_complete)
	stage.objective_updated.disconnect(update_quest)
	current_stage += 1
	if current_stage == stage_count:
		complete = true
		quest_complete.emit(self)

func update_quest(objective: QuestObjective)->void:
	objective_updated.emit(objective)

func set_complete()->void:
	complete = true

func save_data(file: FileAccess)->void:
	for index in range(0, stage_count):
		file.store_var(str(index))
		quest_stages[index].save_data(file)
	file.store_var("END")

func load_data(file: FileAccess)->void:
	var index: String = file.get_var()
	while index != "END":
		if index.to_int() >= quest_stages.size():
			var dummy_stage: QuestStage = QuestStage.new()
			dummy_stage.load_data(file)
		else:
			quest_stages[index.to_int()].load_data(file)
		index = file.get_var()
