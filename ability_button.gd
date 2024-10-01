extends Button
class_name AbilityButton

@export var ability: Ability
var player: Player

func _ready() -> void:
	text = ability.name

func _on_pressed() -> void:
	player.activate_ability(ability)
