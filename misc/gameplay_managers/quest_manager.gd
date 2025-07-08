extends Node
class_name QuestManager
## Global quest manager that processes quest events and saves the quests

@export var quests: Dictionary[String,QuestInfo] = {} ## Dictionary containing all quests
var active_quests: Array[String] ## Contains all active quests
var completed_quests: Array[String] ## Contains all completed quests
var tracked_id: String = "" ## Contains id of currently tracked quest
var quest_data: Dictionary[String, Variant] ## Save data of each quest
var to_save: Array[String] = [ ## Variables to be saved
	"active_quests",
	"completed_quests",
	"tracked_id",
	"quest_data"
]
signal saved(node: QuestManager) ## Emitted when saved
signal loaded(node: QuestManager) ## Emitted when loaded

func _ready() -> void:
	for quest_id in quests.keys():
		quests[quest_id] = quests[quest_id].duplicate_quest()
	EventBus.subscribe("QUEST_START", self, "start_quest")
	EventBus.subscribe("QUEST_EVENT", self, "process_quest_event")

## Starts a quest of the given id
func start_quest(id: String)->void:
	if id not in quests:
		printerr("Attempted to start invalid quest "+id)
		return
	quests[id].activate()
	active_quests.append(id)
	quests[id].quest_complete.connect(complete_quest)
	if tracked_id == "":
		tracked_id = id
		EventBus.broadcast("QUEST_TRACK", quests[tracked_id])
	broadcast_quest_list()

## Processes incoming quest events, broadcasting them to the necessary quests
func process_quest_event(id: String)->void:
	for quest in active_quests:
		for objective in quests[quest].get_current_stage().get_stage_objectives():
			if !objective.complete:
				if id == objective.event_type_choices.keys()[objective.event_type]+":"+objective.event_emitter_name:
					objective.update_objective(id)

## Called when the specified quest is completed
func complete_quest(quest: QuestInfo)->void:
	completed_quests.append(quest.quest_id)
	active_quests.remove_at(active_quests.find(quest.quest_id))
	if tracked_id == quest.quest_id:
		tracked_id = ""
	broadcast_quest_list()

## Sets all quests to complete if they are completed
func update_complete_quests()->void:
	for id in completed_quests:
		quests[id].set_complete()

## Broadcasts an event containing a list of active and complete quests
func broadcast_quest_list()->void:
	var active_quest_list: Array[QuestInfo]
	var completed_quest_list: Array[QuestInfo]
	for quest in active_quests:
		active_quest_list.append(quests[quest])
	for quest in completed_quests:
		completed_quest_list.append(quests[quest])
	EventBus.broadcast("QUEST_LIST_UPDATE", [active_quest_list, completed_quest_list])

#region Saving and Loading
## Executes before making the save dict
func pre_save()->void:
	for quest in active_quests:
		quest_data[quest] = quests[quest].get_save_data()

## Executes after making the save dict
func post_save()->void:
	saved.emit(self)

## Executes before loading data
func pre_load()->void:
	return

## Executes after loading data
func post_load()->void:
	for quest in quest_data:
		if quest not in quests:
			continue
		quests[quest].load_save_data(quest_data[quest])
	update_complete_quests()
	for quest in active_quests:
		quests[quest].activate()
		if !quests[quest].quest_complete.is_connected(complete_quest):
			quests[quest].quest_complete.connect(complete_quest)
	EventBus.broadcast("QUEST_TRACK_STOP", "NULLDATA")
	if tracked_id != "":
		EventBus.broadcast("QUEST_TRACK", quests[tracked_id])
	broadcast_quest_list()
	loaded.emit(self)
#endregion
