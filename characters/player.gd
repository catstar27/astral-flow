extends Character
class_name Player

func _input(event: InputEvent) -> void:
	if event.is_action_released("interact") and interactive_in_range != null:
		interact()

func populate_ability_list()->void:
	for child in get_children():
		if child is Ability:
			GlobalRes.hud._add_ability(child)
