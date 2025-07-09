extends PanelContainer
class_name QuestLog
## GUI element containing all active and completed quests

const quest_button_scn: PackedScene = preload("uid://c3maf43m7h1c1") ## Scene for QuestButton
@onready var quest_icon: TextureRect = %QuestIcon ## Icon for tracked quest
@onready var quest_name: Label = %QuestName ## Name label for tracked quest
@onready var objective_conainer: VBoxContainer = %ObjectiveContainer ## Container for objective labels
var active_quest_list: VBoxContainer ## Container holding buttons for active quests
var complete_quest_list: VBoxContainer ## Container holding buttons for complete quests
var cur_button: QuestButton = null ## Button pertaining to tracked quest
var tracked_quest: QuestInfo = null ## Quest being tracked
signal opened ## Emitted when the menu opens
signal closed ## Emitted when the menu closes

func _ready() -> void:
	EventBus.subscribe("QUEST_LIST_UPDATE", self, "update_quest_list")
	EventBus.subscribe("QUEST_TRACK", self, "update_tracked_quest")
	active_quest_list = get_node("HBoxContainer/QuestListContainer/TabMenu/Active/ActiveQuestList")
	complete_quest_list = get_node("HBoxContainer/QuestListContainer/TabMenu/Complete/CompleteQuestList")

## Grabs focus on the current button if possible
func focus_current()->void:
	if cur_button != null && is_instance_valid(cur_button):
		cur_button.grab_focus()

## Makes an objective label and returns it
func get_objective_label()->RichTextLabel:
	var new_label: RichTextLabel = RichTextLabel.new()
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	new_label.bbcode_enabled = true
	new_label.add_theme_font_size_override("normal_font_size", 16)
	new_label.fit_content = true
	new_label.use_parent_material = true
	return new_label

## Opens the menu
func open()->void:
	EventBus.broadcast("PAUSE", "NULLDATA")
	show()
	if is_instance_valid(cur_button):
		cur_button.grab_focus()
	opened.emit()

## Closes the menu
func close()->void:
	hide()
	EventBus.broadcast("UNPAUSE", "NULLDATA")
	closed.emit()

## Displays the given quest in the menu
func display_quest(quest: QuestInfo)->void:
	quest_icon.texture = quest.quest_icon
	quest_name.text = quest.quest_name
	for child in objective_conainer.get_children():
		child.queue_free()
	for stage in quest.quest_stages:
		if stage.active || stage.complete:
			for objective in stage.quest_objectives.values():
				var label: RichTextLabel = get_objective_label()
				label.text = ""
				label.text += objective.description
				if objective.total_count > 0:
					label.text += " ("+str(objective.current_count)+"/"+str(objective.total_count)+")"
				label.text += " ["
				if objective.complete:
					label.text += "✓"
				label.text += "]"
				objective_conainer.add_child(label)

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
		new_quest_button.focused_quest.connect(display_quest)
		new_quest_button.pressed_quest.connect(track_quest)
		new_quest_button.unpressed_quest.connect(untrack_quest)
		if quest == tracked_quest:
			cur_button = new_quest_button
			new_quest_button.set_pressed_no_signal(true)
		active_quest_list.add_child(new_quest_button)
	active_quest_list.move_child(active_quest_list.get_child(0), -1)
	if active_quest_list.get_child_count() > 1:
		active_quest_list.get_child(-1).hide()
	for quest in quests[1]:
		var new_quest_button = quest_button_scn.instantiate()
		new_quest_button.select_quest(quest)
		new_quest_button.focused_quest.connect(display_quest)
		new_quest_button.toggle_mode = false
		complete_quest_list.add_child(new_quest_button)
	complete_quest_list.move_child(complete_quest_list.get_child(0), -1)
	if complete_quest_list.get_child_count() > 1:
		complete_quest_list.get_child(-1).hide()

## Updates the tracked_quest variable
func update_tracked_quest(quest: QuestInfo)->void:
	tracked_quest = quest
