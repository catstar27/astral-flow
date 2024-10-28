extends Button
class_name AbilityButton

@export var ability: Ability

func _ready() -> void:
	text = ability.name

func _on_pressed() -> void:
	if !GlobalRes.selection_cursor.selected == ability:
		GlobalRes.selection_cursor.select(ability)
	else:
		GlobalRes.selection_cursor.deselect()
