extends VBoxContainer
class_name QuestTracker
## Tracks the currently tracked quest, displaying information about the current stage

@export var manage_manually: bool = false ## Whether this should not use the EventBus to allow manual quest control
@export var animate: bool = true ## Whether to animate the tracker
@export var show_all_stages: bool = false ## Whether this should show all stages up to the current one
@export var show_in_combat: bool = false ## Whether this should hide in combat
@onready var quest_icon: TextureRect = %Icon ## Icon of the current quest
@onready var quest_name: Label = %Name ## Name of the current quest
@onready var name_icon_container: HBoxContainer = %NameIconContainer ## Container holding name and icon
@onready var objective_container: VBoxContainer = %ObjectiveContainer ## Container holding the objective inf
var objective_labels: Dictionary[QuestObjective, RichTextLabel] ## Dictionary of QuestObjectives and their labels
var quest_path_labels: Dictionary[QuestPath, LabelPair] ## Dictionary of QuestPath name and 'or' labels
var stage_path_labels: Dictionary[StagePath, RichTextLabel] ## Dictionary of StagePath 'or' labels
var tracked_quest: QuestInfo = null ## Currently tracked quest
var in_combat: bool = false ## Whether the game is in combat
var updating_objective: bool = false ## Whether objectives are updating
var starting_tracking: bool = false ## Whether a quest is starting to be tracked
var animating: bool = false ## Whether the tracker is currently animating
signal objective_updated ## Emitted when an objective is done updating
#signal animation_finished ## Emitted when done animating the tracker

class LabelPair:
	var name_label: RichTextLabel
	var or_label: RichTextLabel

	#await create_tween().tween_property(self, "position", 
		#Vector2(position.x, get_viewport_rect().size.y-quest_container.size.y), .1).finished
	#if play_anim:
		#var copy_label: RichTextLabel = get_objective_label()
		#copy_label.text = objective_labels[objective].text
		#copy_label.size = objective_labels[objective].size
		#add_child(copy_label)
		#copy_label.global_position = objective_labels[objective].global_position
		#copy_label.global_position.x += objective_labels[objective].size.x
		#await create_tween().tween_property(copy_label, "global_position", objective_labels[objective].global_position, .5).finished
		#objective_labels[objective].modulate = Color.WHITE
		#copy_label.queue_free()

func _ready() -> void:
	if !manage_manually:
		EventBus.subscribe("QUEST_TRACK", self, "track_quest")
		EventBus.subscribe("QUEST_TRACK_STOP", self, "stop_tracking")
		EventBus.subscribe("COMBAT_STARTED", self, "start_combat")
		EventBus.subscribe("COMBAT_ENDED", self, "end_combat")

## Tracks the given quest
func track_quest(quest: QuestInfo)->void:
	stop_tracking()
	tracked_quest = quest
	quest_icon.texture = quest.quest_icon
	quest_name.text = quest.quest_name
	quest.path_updated.connect(update_quest_path)
	quest.quest_complete.connect(complete_quest)
	for quest_path in quest.quest_paths:
		if quest.quest_paths.size() > 1:
			var quest_path_label: RichTextLabel = get_objective_label()
			quest_path_label.add_theme_font_size_override("bold_font_size", 20)
			quest_path_label.text = "[b]"+quest_path.id+"[/b]"
			objective_container.add_child(quest_path_label)
			quest_path_labels[quest_path] = LabelPair.new()
			quest_path_labels[quest_path].name_label = quest_path_label
		if quest.complete && quest_path != quest.complete_path:
			var label: RichTextLabel = get_objective_label()
			label.text = "[color=light_coral]Skipped![/color]"
			objective_container.add_child(label)
		else:
			display_quest_path(quest_path, quest.complete)
		if quest_path != quest.quest_paths[-1]:
			var quest_path_label: RichTextLabel = get_objective_label()
			quest_path_label.add_theme_font_size_override("bold_font_size", 20)
			quest_path_label.text = "[b][color=goldenrod]  --OR--  [/color][/b]"
			objective_container.add_child(quest_path_label)
			quest_path_labels[quest_path].or_label = quest_path_label
	show()
	#if animate:
		#animating = true
		#var fake_name_icon: HBoxContainer = name_icon_container.duplicate()
		#var fake_objective_container: VBoxContainer = objective_container.duplicate()
		#%AnimationNode.add_child(fake_name_icon)
		#%AnimationNode.add_child(fake_objective_container)
		#name_icon_container.modulate = Color.TRANSPARENT
		#objective_container.modulate = Color.TRANSPARENT
		#fake_name_icon.global_position.x = global_position.x
		#fake_name_icon.global_position.y = get_viewport_rect().size.y
		#fake_objective_container.global_position.x = global_position.x
		#fake_objective_container.global_position.y = get_viewport_rect().size.y
		#create_tween().tween_property(fake_name_icon, "global_position", name_icon_container.global_position, .5)
		#await create_tween().tween_property(fake_objective_container, "global_position", objective_container.global_position, .5).finished
		#fake_name_icon.queue_free()
		#fake_objective_container.queue_free()
		#name_icon_container.modulate = Color.WHITE
		#objective_container.modulate = Color.WHITE
		#animating = false
		#animation_finished.emit()

## Displays a quest path
func display_quest_path(quest_path: QuestPath, complete: bool)->void:
	var shown_stages: Array[QuestStage] = quest_path.get_path_stages()
	for stage in quest_path.path_stages:
		if stage.complete && show_all_stages:
			for objective in stage.completed_path.path_objectives:
				display_objective(objective, stage.complete)
		elif complete || stage in shown_stages:
			for path in stage.stage_paths:
				for objective in path.path_objectives:
					display_objective(objective, stage.complete)
				if !stage.complete && stage.stage_paths.size() > 1 && path != stage.stage_paths[-1]:
					var label: RichTextLabel = get_objective_label()
					label.text = "[b][color=goldenrod]  --OR--  [/color][/b]"
					objective_container.add_child(label)
					stage_path_labels[path] = label

func display_objective(objective: QuestObjective, stage_complete: bool)->void:
	while updating_objective:
		await objective_updated
	if objective.is_secret && !objective.complete:
		return
	var label: RichTextLabel = get_objective_label()
	if objective.is_optional:
		label.text += "[color=sky_blue]"
	label.text += objective.description
	if objective.total_count > 0:
		label.text += " ("+str(objective.current_count)+"/"+str(objective.total_count)+")"
	if !objective.complete && objective.is_optional && stage_complete:
		label.text += " ☒"
	elif !objective.complete:
		label.text += " ☐"
	elif objective.complete:
		label.text += " ☑"
	objective_container.add_child(label)
	objective_labels[objective] = label
	objective.objective_updated.connect(update_objective)
	objective.objective_completed.connect(update_objective)

## Updates given objective's label
func update_objective(objective: QuestObjective)->void:
	while updating_objective:
		await objective_updated
	if objective not in objective_labels:
		return
	var label: RichTextLabel = objective_labels[objective]
	label.text = ""
	if objective.is_optional:
		label.text += "[color=sky_blue]"
	label.text += objective.description
	if objective.total_count > 0:
		label.text += " ("+str(objective.current_count)+"/"+str(objective.total_count)+")"
	if !objective.complete:
		label.text += " ☐"
	elif objective.complete:
		label.text += " ☑"

## Updates given quest path
func update_quest_path(quest_path: QuestPath, completed_stage: QuestStage)->void:
	while updating_objective:
		await objective_updated
	var temp: Array[RichTextLabel]
	var desired_stages: Array[QuestStage] = quest_path.get_path_stages()
	var first_child_index: int = -1
	if completed_stage not in desired_stages:
		for stage_path in completed_stage.stage_paths:
			if stage_path in stage_path_labels:
				stage_path_labels[stage_path].queue_free()
				stage_path_labels.erase(stage_path)
			for objective in stage_path.path_objectives:
				if objective in objective_labels:
					if first_child_index == -1:
						first_child_index = objective_labels[objective].get_index()
					objective_labels[objective].queue_free()
					objective_labels.erase(objective)
					objective.objective_updated.disconnect(update_objective)
					objective.objective_completed.disconnect(update_objective)
	if completed_stage == desired_stages[-1]:
		return
	var next_stage: QuestStage = desired_stages[desired_stages.find(completed_stage)+1]
	if first_child_index == -1:
		var last_objective: QuestObjective = completed_stage.stage_paths[-1].path_objectives[-1]
		first_child_index = objective_labels[last_objective].get_index()+1
	while objective_container.get_child_count() > first_child_index:
		temp.append(objective_container.get_child(first_child_index))
		objective_container.remove_child(objective_container.get_child(first_child_index))
	for path in next_stage.stage_paths:
		for objective in path.path_objectives:
			display_objective(objective, false)
	while !temp.is_empty():
		objective_container.add_child(temp.pop_front())

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
	if !show_in_combat:
		hide()

## Ends combat and shows the tracker if it was tracking a quest
func end_combat()->void:
	in_combat = false
	show()

## Stops tracking any quests
func stop_tracking()->void:
	if tracked_quest == null:
		return
	for objective in objective_labels:
		objective.objective_updated.disconnect(update_objective)
		objective.objective_completed.disconnect(update_objective)
	for child in objective_container.get_children():
		child.queue_free()
	objective_labels.clear()
	quest_path_labels.clear()
	stage_path_labels.clear()
	tracked_quest.path_updated.disconnect(update_quest_path)
	tracked_quest.quest_complete.disconnect(complete_quest)
	tracked_quest = null
	hide()

## Shows the display if it is currently tracking a quest
func show_if_tracking()->void:
	if tracked_quest != null && !in_combat:
		show()
