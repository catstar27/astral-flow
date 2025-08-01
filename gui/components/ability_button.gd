@tool
extends Button
class_name AbilityButton
## Button that holds an ability makes the user select it when pressed

@export var ability: Ability: ## Ability to be held
	set(new_ability):
		ability = new_ability
		if ability != null:
			icon = ability.icon

## Sets the button's ability and updates the text
func set_ability(new_ability: Ability)->void:
	ability = new_ability
	icon = ability.icon

## Clears the button's ability, making it blank
func clear_ability()->void:
	ability = null
	icon = null

func _on_pressed() -> void:
	if ability.user.selected_ability == null:
		ability.user.select_ability(ability)
	elif ability.user.selected_ability != ability:
		ability.user.deselect_ability()
		ability.user.select_ability(ability)
	else:
		ability.user.deselect_ability()
