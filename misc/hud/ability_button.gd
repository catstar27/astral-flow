extends Button
class_name AbilityButton

@export var ability: Ability

func _ready() -> void:
	text = ability.display_name

func _on_pressed() -> void:
	EventBus.broadcast(EventBus.Event.new("ABILITY_BUTTON_PRESSED", ability))
	if ability.user.selected_ability == null:
		ability.user.select_ability(ability)
	elif ability.user.selected_ability != ability:
		ability.user.deselect_ability()
		ability.user.select_ability(ability)
	else:
		ability.user.deselect_ability()
