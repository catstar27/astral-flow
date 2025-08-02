extends Control
class_name QuestLog
## GUI element containing all active and completed quests

const quest_button_scn: PackedScene = preload("uid://c3maf43m7h1c1") ## Scene for QuestButton
@onready var active_quest_list: VBoxContainer = %ActiveQuestList ## Container holding buttons for active quests
@onready var active_quest_label: Label = %ActiveQuestLabel ## Label for when active quest is empty
@onready var complete_quest_list: VBoxContainer = %CompleteQuestList ## Container holding buttons for complete quests
@onready var complete_quest_label: Label = %CompleteQuestLabel ## Label for when complete quest is empty
var cur_button: QuestButton = null ## Button pertaining to tracked quest
var tracked_quest: QuestInfo = null ## Quest being tracked
signal opened ## Emitted when the menu opens
signal closed ## Emitted when the menu closes

func _ready() -> void:
	EventBus.subscribe("QUEST_LIST_UPDATE", self, "update_quest_list")
	EventBus.subscribe("QUEST_TRACK", self, "update_tracked_quest")

## Grabs focus on the current button if possible
func focus_current()->void:
	if !is_node_ready():
		return
	if cur_button != null && cur_button.is_visible_in_tree():
		cur_button.grab_focus()
	elif active_quest_list.is_visible_in_tree() && active_quest_list.get_child_count() > 1:
		active_quest_list.get_child(0).grab_focus()
	elif complete_quest_list.get_child_count() > 1:
		complete_quest_list.get_child(0).grab_focus()

## Opens the menu
func open()->void:
	EventBus.broadcast("PAUSE", "NULLDATA")
	show()
	focus_current()
	opened.emit()

## Closes the menu
func close()->void:
	hide()
	EventBus.broadcast("UNPAUSE", "NULLDATA")
	closed.emit()

## Tracks the given quest in the QuestTracker
func track_quest(button: QuestButton, quest: QuestInfo)->void:
	if cur_button != button && cur_button != null:
		cur_button.set_pressed_no_signal(false)
	EventBus.broadcast("QUEST_TRACK", quest)
	cur_button = button

## Untracks the given quest in the QuestTracker
func untrack_quest(quest: QuestInfo)->void:
	if quest == tracked_quest:
		EventBus.broadcast("QUEST_TRACK_STOP", "NULLDATA")

## Updates the list of quests
func update_quest_list(quests: Array)->void:
	for child in active_quest_list.get_children():
		if child is not Label:
			child.queue_free()
	for child in complete_quest_list.get_children():
		if child is not Label:
			child.queue_free()
	for quest in quests[0]:
		var new_quest_button = quest_button_scn.instantiate()
		new_quest_button.select_quest(quest)
		new_quest_button.focused_quest.connect(%QuestTracker.track_quest)
		new_quest_button.pressed_quest.connect(track_quest)
		new_quest_button.unpressed_quest.connect(untrack_quest)
		if quest == tracked_quest:
			cur_button = new_quest_button
			new_quest_button.set_pressed_no_signal(true)
		active_quest_list.add_child(new_quest_button)
	active_quest_list.move_child(active_quest_label, -1)
	if active_quest_list.get_child_count() > 1:
		active_quest_label.hide()
	for quest in quests[1]:
		var new_quest_button = quest_button_scn.instantiate()
		new_quest_button.select_quest(quest)
		new_quest_button.focused_quest.connect(%QuestTracker.track_quest)
		new_quest_button.toggle_mode = false
		complete_quest_list.add_child(new_quest_button)
	complete_quest_list.move_child(complete_quest_label, -1)
	if complete_quest_list.get_child_count() > 1:
		complete_quest_label.hide()

## Updates the tracked_quest variable
func update_tracked_quest(quest: QuestInfo)->void:
	tracked_quest = quest
