extends Button
class_name AbilityButton

@export var ability: Ability

func set_ability(new_ability: Ability)->void:
	ability = new_ability
	text = new_ability.display_name

func clear_ability()->void:
	ability = null
	text = ""

func _on_pressed() -> void:
	EventBus.broadcast("ABILITY_BUTTON_PRESSED", ability)
	if ability.user.selected_ability == null:
		ability.user.select_ability(ability)
	elif ability.user.selected_ability != ability:
		ability.user.deselect_ability()
		ability.user.select_ability(ability)
	else:
		ability.user.deselect_ability()
