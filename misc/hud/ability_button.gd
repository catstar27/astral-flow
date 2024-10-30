extends Button
class_name AbilityButton

@export var ability: Ability

func _ready() -> void:
	text = ability.name

func _on_pressed() -> void:
	if !GlobalRes.selection_cursor.selected == ability.user:
		GlobalRes.selection_cursor.select(ability.user)
	if ability.user.selected_ability == null:
		ability.user.select_ability(ability)
	elif ability.user.selected_ability != ability:
		ability.user.deselect_ability()
		ability.user.select_ability(ability)
	else:
		ability.user.deselect_ability()
