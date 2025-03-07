extends Node
class_name QuestManager
## Global quest manager that processes quest events and saves the quests

@export var quests: Dictionary[String,QuestInfo] = {} ## Dictionary containing all quests
var active_quests: Array[String] ## Contains all active quests
var completed_quests: Array[String] ## Contains all completed quests
var tracked_id: String = "" ## Contains id of currently tracked quest
var to_save: Array[String] = [ ## Variables to be saved
	"active_quests",
	"completed_quests",
	"tracked_id"
]
signal saved(node: QuestManager) ## Emitted when saved
signal loaded(node: QuestManager) ## Emitted when loaded

func _ready() -> void:
	EventBus.subscribe("QUEST_START", self, "start_quest")

## Starts a quest of the given id
func start_quest(id: String)->void:
	if id not in quests:
		printerr("Attempted to start invalid quest "+id)
		return
	quests[id].activate()
	active_quests.append(id)
	if tracked_id == "":
		tracked_id = id
		EventBus.broadcast("QUEST_TRACK", quests[tracked_id])

## Called when the specified quest is completed
func complete_quest(id: String)->void:
	completed_quests.append(id)
	active_quests.remove_at(active_quests.find(id))
	if tracked_id == id:
		tracked_id = ""
		EventBus.broadcast("QUEST_TRACK_STOP", "NULLDATA")

## Sets all quests to complete if they are completed
func update_complete_quests()->void:
	for id in completed_quests:
		quests[id].set_complete()

#region Saving and Loading
## Saves every quest in the game
func save_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.WRITE)
	for var_name in to_save:
		file.store_var(var_name)
		file.store_var(get(var_name))
	file.store_var("END")
	for id in quests:
		file.store_var(id)
		quests[id].save_data(file)
	file.store_var("END")
	file.close()
	saved.emit(self)

## Loads every quest in the game
func load_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.READ)
	var var_name: String = file.get_var()
	while var_name != "END":
		set(var_name, file.get_var())
		var_name = file.get_var()
	var id: String = file.get_var()
	while id != "END":
		if id not in quests:
			var dummy_quest: QuestInfo = QuestInfo.new()
			dummy_quest.load_data(file)
		else:
			quests[id].load_data(file)
		id = file.get_var()
	file.close()
	update_complete_quests()
	EventBus.broadcast("QUEST_TRACK", quests[tracked_id])
	loaded.emit(self)
#endregion
