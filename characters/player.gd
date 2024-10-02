extends Character
class_name Player

func _ready() -> void:
	GlobalRes.connect("globals_initialized", populate_ability_list)

func populate_ability_list()->void:
	for child in get_children():
		if child is Ability:
			GlobalRes.hud._add_ability(child)
