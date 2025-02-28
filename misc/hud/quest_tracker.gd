extends Control

@export var objective_label_settings: LabelSettings
@onready var quest_name: Label = %Name
@onready var quest_container: VBoxContainer = %QuestContainer
@onready var objective_container: VBoxContainer = %ObjectiveContainer
var tracked_quest: QuestInfo = null

func _ready() -> void:
	EventBus.subscribe("QUEST_TRACK", self, "change_quest")
	EventBus.subscribe("QUEST_TRACK_STOP", self, "stop_tracking")
	EventBus.subscribe("COMBAT_STARTED", self, "hide")
	EventBus.subscribe("COMBAT_ENDED", self, "show_if_tracking")

func change_quest(quest: QuestInfo)->void:
	tracked_quest = quest
	quest_name.text = tracked_quest.quest_name
	for child in objective_container.get_children():
		child.queue_free()
	for objective in tracked_quest.get_current_stage().get_stage_objectives():
		var new_label: Label = Label.new()
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		new_label.label_settings = objective_label_settings
		new_label.text = objective.description
		new_label.use_parent_material = true
		if objective.total_count > 0:
			new_label.text += " ("+str(objective.current_count)+"/"+str(objective.total_count)+")"
		objective_container.add_child(new_label)
	position.y = get_viewport_rect().size.y-quest_container.size.y
	show()

func stop_tracking()->void:
	tracked_quest = null
	hide()

func show_if_tracking()->void:
	if tracked_quest != null:
		show()
