extends Character
class_name Enemy

var combat_trigger: Area2D = %CombatTrigger

func _ready() -> void:
	_setup()
