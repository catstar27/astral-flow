@tool
extends Button
class_name SkillEffectButton
## Button containing a reference to a skill effect

@export var effect: SkillEffect ## The effect reference by this button

## Sets the effect in this button
func set_effect(new_effect: SkillEffect)->void:
	effect = new_effect
	icon = effect.icon

## Clears the effect in this button
func clear_effect()->void:
	effect = null
	icon = null
