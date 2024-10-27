extends Character
class_name Enemy

@onready var combat_trigger: Area2D = %CombatTrigger

func _ready() -> void:
	_setup()

func _combat_trigger_entered(body: Node2D) -> void:
	if body is Player:
		GlobalRes.main.start_combat(body, self)
