extends Button
class_name AbilityButton

@export var ability: Ability

func _ready() -> void:
	text = ability.name

func _on_pressed() -> void:
	GlobalRes.player.activate_ability(ability)
