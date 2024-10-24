extends Node2D
class_name Ability

var target
enum target_type_choice {target_self, target_allies, target_enemies, target_all}
@onready var user: Character = get_parent()
@export var ap_cost: int = 0
@export var mp_cost: int = 0
@export var ability_range: int = 1
@export var target_type: target_type_choice = target_type_choice.target_all
@export var needs_line_of_sight: bool = 1

func is_destination_valid(destination: Vector2)->bool:
	var dest_path: Array[Vector2i] = GlobalRes.map.get_nav_path(user.position, destination)
	if dest_path.size()<=ability_range+1:
		return true
	return false

func activate(_destination: Vector2)->void:
	return
 
