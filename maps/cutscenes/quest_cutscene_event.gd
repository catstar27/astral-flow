extends CutsceneEvent
class_name QuestCutsceneEvent
## A cutscene event which either triggers a quest event or starts a quest

@export var start_quest: String = "" ## Name of a quest to start
@export var quest_event: String = "" ## Quest event id to emit
