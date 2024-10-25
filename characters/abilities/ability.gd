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

func get_valid_destinations()->Array[Vector2]:
	if target_type == target_type_choice.target_self:
		return [user.position]
	var destinations: Array[Vector2] = []
	var scale_factor: int = GlobalRes.map.tile_set.tile_size.x
	for x in range(user.position.x-ability_range*scale_factor, user.position.x+ability_range*scale_factor+1, scale_factor):
		for y in range(user.position.y-ability_range*scale_factor, user.position.y+ability_range*scale_factor+1, scale_factor):
			if Vector2(x,y) != user.position:
				var path_length: int = GlobalRes.map.get_nav_path(user.position, Vector2(x,y), false).size()
				if path_length<=ability_range+1 && path_length>0:
					destinations.append(Vector2(x, y))
	return destinations

func is_destination_valid(destination: Vector2)->bool:
	var dest_path: Array[Vector2i] = GlobalRes.map.get_nav_path(user.position, destination, false)
	if dest_path.size()<=ability_range:
		return true
	return false

func activate(_destination: Vector2)->void:
	return
 
