extends Node
class_name QuestManager

@export var quests: Dictionary[String,QuestInfo] = {}

func _ready() -> void:
	EventBus.subscribe("QUEST_START", self, "start_quest")

func start_quest(id: String)->void:
	if id not in quests:
		printerr("Attempted to start invalid quest "+id)
		return
	quests[id].activate()
	EventBus.broadcast("QUEST_TRACK_IF_BLANK", quests[id])
