extends Control
class_name QuestTracker
## Tracks the currently tracked quest, displaying information about the current stage

@export var objective_label_settings: LabelSettings ## Settings for the objective labels
@onready var quest_name: Label = %Name ## Name of the current quest
@onready var quest_container: VBoxContainer = %QuestContainer ## Container holding the display info
@onready var objective_container: VBoxContainer = %ObjectiveContainer ## Container holding the objective info
var tracked_quest: QuestInfo = null ## Currently tracked quest
var in_combat: bool = false ## Whether the game is in combat

func _ready() -> void:
	EventBus.subscribe("QUEST_TRACK", self, "change_quest")
	EventBus.subscribe("QUEST_TRACK_STOP", self, "stop_tracking")
	EventBus.subscribe("COMBAT_STARTED", self, "start_combat")
	EventBus.subscribe("COMBAT_ENDED", self, "end_combat")

## Changes the currently tracked quest
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
	if !in_combat:
		show()

## Starts the combat state and hides the tracker
func start_combat()->void:
	in_combat = true
	hide()

## Ends combat and shows the tracker if it was tracking a quest
func end_combat()->void:
	in_combat = false
	show_if_tracking()

## Stops tracking any quests
func stop_tracking()->void:
	tracked_quest = null
	hide()

## Shows the display if it is currently tracking a quest
func show_if_tracking()->void:
	if tracked_quest != null && !in_combat:
		show()
