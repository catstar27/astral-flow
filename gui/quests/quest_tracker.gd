extends Control
class_name QuestTracker
## Tracks the currently tracked quest, displaying information about the current stage

@onready var quest_icon: TextureRect = %Icon ## Icon of the current quest
@onready var quest_name: Label = %Name ## Name of the current quest
@onready var quest_container: VBoxContainer = %QuestContainer ## Container holding the display info
@onready var name_icon_container: HBoxContainer = %NameIconContainer ## Container holding name and icon
@onready var objective_container: VBoxContainer = %ObjectiveContainer ## Container holding the objective info
var objective_labels: Dictionary[QuestObjective, RichTextLabel] ## Array of the labels containing objective info
var tracked_quest: QuestInfo = null ## Currently tracked quest
var in_combat: bool = false ## Whether the game is in combat
var updating_objective: int = 0 ## Number of objectives updating
var starting_tracking: bool = false ## Whether a quest is starting to be tracked
signal started_tracking ## Emitted when a new quest is tracked
signal objective_updated ## Emitted when a quest objective is updated

func _ready() -> void:
	EventBus.subscribe("QUEST_TRACK", self, "change_quest")
	EventBus.subscribe("QUEST_TRACK_STOP", self, "stop_tracking")
	EventBus.subscribe("COMBAT_STARTED", self, "start_combat")
	EventBus.subscribe("COMBAT_ENDED", self, "end_combat")

## Changes the currently tracked quest
func change_quest(quest: QuestInfo)->void:
	if tracked_quest == quest || starting_tracking:
		return
	while updating_objective > 0:
		await objective_updated
	if tracked_quest != null:
		tracked_quest.quest_complete.disconnect(complete_quest)
		tracked_quest.stage_started.disconnect(build_labels)
	starting_tracking = true
	tracked_quest = quest
	for objective in objective_labels.keys():
		objective_labels[objective].queue_free()
		objective_labels.erase(objective)
	quest.quest_complete.connect(complete_quest)
	quest_name.text = tracked_quest.quest_name
	quest_icon.texture = tracked_quest.quest_icon
	quest_icon.modulate = Color.TRANSPARENT
	quest_name.modulate = Color.TRANSPARENT
	if quest != tracked_quest:
		return
	await get_tree().process_frame
	position.y = get_viewport_rect().size.y-quest_container.size.y
	if quest != tracked_quest:
		return
	objective_container.hide()
	if !in_combat:
		show()
	while !is_visible_in_tree() && !in_combat:
		await visibility_changed
	await get_tree().process_frame
	var fake_name_icon: HBoxContainer = name_icon_container.duplicate()
	fake_name_icon.get_child(0).modulate = Color.WHITE
	fake_name_icon.get_child(1).modulate = Color.WHITE
	add_child(fake_name_icon)
	fake_name_icon.global_position = Vector2(name_icon_container.global_position.x, get_viewport_rect().size.y)
	fake_name_icon.size = name_icon_container.size
	await create_tween().tween_property(fake_name_icon, "global_position", name_icon_container.global_position, .5).finished
	quest_icon.modulate = Color.WHITE
	quest_name.modulate = Color.WHITE
	fake_name_icon.queue_free()
	objective_container.show()
	await get_tree().create_timer(.1).timeout
	build_labels()
	quest.stage_started.connect(build_labels)
	starting_tracking = false
	if !in_combat:
		show()
	started_tracking.emit()

## Updates the label corresponding to the quest objective given
func update_objective(objective: QuestObjective, play_anim: bool = false)->void:
	updating_objective += 1
	if play_anim:
		objective_labels[objective].modulate = Color.TRANSPARENT
	objective_labels[objective].text = ""
	objective_labels[objective].text += objective.description
	if objective.total_count > 0:
		objective_labels[objective].text += " ("+str(objective.current_count)+"/"+str(objective.total_count)+")"
	objective_labels[objective].text += " ["
	if objective.complete:
		objective_labels[objective].text += "✓"
	objective_labels[objective].text += "]"
	await get_tree().process_frame
	await create_tween().tween_property(self, "position", 
		Vector2(position.x, get_viewport_rect().size.y-quest_container.size.y), .1).finished
	if play_anim:
		var copy_label: RichTextLabel = get_objective_label()
		copy_label.text = objective_labels[objective].text
		copy_label.size = objective_labels[objective].size
		add_child(copy_label)
		copy_label.global_position = objective_labels[objective].global_position
		copy_label.global_position.x += objective_labels[objective].size.x
		await create_tween().tween_property(copy_label, "global_position", objective_labels[objective].global_position, .5).finished
		objective_labels[objective].modulate = Color.WHITE
		copy_label.queue_free()
	updating_objective -= 1
	objective_updated.emit()

## Updates the quest tracker information
func build_labels(_stage: Resource = null)->void:
	var objectives: Array[QuestObjective] = tracked_quest.get_tracked_objectives()
	for objective in objective_labels.keys():
		if objective not in objectives:
			objective_labels[objective].queue_free()
			objective_labels.erase(objective)
	for objective in objectives:
		if !objective.objective_updated.is_connected(update_objective):
			objective.objective_updated.connect(update_objective)
		if !objective.objective_completed.is_connected(update_objective):
			objective.objective_completed.connect(update_objective)
		if objective not in objective_labels.keys():
			var new_label: RichTextLabel = get_objective_label()
			objective_container.add_child(new_label)
			objective_labels[objective] = new_label
			update_objective(objective, true)

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

## Fades out the tracker when the quest completes
func complete_quest(_quest: QuestInfo)->void:
	await create_tween().tween_property(self, "modulate", Color.TRANSPARENT, 1).finished
	stop_tracking()
	modulate = Color.WHITE

## Starts the combat state and hides the tracker
func start_combat()->void:
	in_combat = true
	hide()

## Ends combat and shows the tracker if it was tracking a quest
func end_combat()->void:
	in_combat = false
	var old_tracked: QuestInfo = tracked_quest
	stop_tracking()
	change_quest(old_tracked)

## Stops tracking any quests
func stop_tracking()->void:
	if tracked_quest != null:
		tracked_quest.quest_complete.disconnect(complete_quest)
		tracked_quest.stage_started.disconnect(build_labels)
	tracked_quest = null
	hide()

## Shows the display if it is currently tracking a quest
func show_if_tracking()->void:
	if tracked_quest != null && !in_combat:
		show()
