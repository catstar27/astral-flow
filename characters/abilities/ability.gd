extends Node2D
class_name Ability

var target
enum target_type_choice {target_self, target_allies, target_enemies, target_all}
@onready var user: Character = get_parent()
@export var ap_cost: int = 0
@export var mp_cost: int = 0
@export var ability_range: int = 1
@export var target_type: target_type_choice = target_type_choice.target_all

func activate(_destination: Vector2)->void:
	return
