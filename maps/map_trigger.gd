@tool
extends Area2D
class_name MapTrigger
## A trigger in a game map

@export var shape: Shape2D:
	set(new_shape):
		shape = new_shape
		%Collision.shape = new_shape
@export var one_shot: bool = true ## Whether this trigger disables after triggering
@export var dialogue: DialogicTimeline = null ## Dialogue to trigger when this trigger goes off
@export var pause_music: bool = false ## Whether this dialogue will pause music
@export var quest: QuestInfo = null ## Quest to trigger when this trigger goes off
@export var cutscene: String = "" ## Name of cutscene to trigger when this trigger goes off
var active: bool = true ## Whether this trigger is active
var to_save: Array[StringName] = [ ## Variables to save
	"active",
]
signal saved(node: MapTrigger)
signal loaded(node: MapTrigger)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("PartyMember") && active:
		if one_shot:
			active = false
		if dialogue != null:
			EventBus.broadcast("ENTER_DIALOGUE", [dialogue, pause_music])
		if quest != null:
			EventBus.broadcast("QUEST_START", quest.quest_id)
		if cutscene != "":
			EventBus.broadcast("PLAY_CUTSCENE", cutscene)

#region Save and Load
## Executes before making the save dict
func pre_save()->void:
	return

## Executes after making the save dict
func post_save()->void:
	saved.emit(self)

## Executes before loading data
func pre_load()->void:
	return

## Executes after loading data
func post_load()->void:
	loaded.emit(self)
#endregion
