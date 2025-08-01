@tool
extends Interactive
class_name DamageActivationInteractive
## Interactive that emits a signal when dealt damage matching a specific damage type

## Required damage type to trigger this interactive
@export var damage_type_required: Ability.damage_type_options = Ability.damage_type_options.none
@export var dialogue_unlocked: DialogicTimeline ## Dialogue to play when this is unlocked
var triggered: bool = false ## Whether this has been triggered
signal unlocked(name: String) ## Emitted when this is unlocked

func _init() -> void:
	to_save.append("triggered")

## Called when this is dealt damage; triggers if the type matches
func damage(_source: Node, _amount: int, damage_type: Ability.damage_type_options, _ignore_armor: bool = false)->void:
	if triggered:
		return
	if damage_type == damage_type_required || damage_type_required == Ability.damage_type_options.none:
		trigger()

## Triggers this interactive
func trigger()->void:
	triggered = true
	EventBus.broadcast("QUEST_EVENT", "trigger_switch:"+id)
	dialogue_timeline = dialogue_unlocked
	unlocked.emit("unlocked")
	sprite.frame = 1

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
	super.post_load()
	if triggered:
		trigger()
	loaded.emit(self)
#endregion
