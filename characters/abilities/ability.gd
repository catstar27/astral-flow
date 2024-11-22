extends Node2D
class_name Ability

enum target_type_choice {target_self, target_allies, target_enemies, target_all}
enum damage_type_choice {blunt, electric}
enum skill_used_choice {intelligence, agility, strength, endurance, resolve, charisma, passion}
@onready var user: Character = get_parent()
@export_subgroup("Costs")
@export var ap_cost: int = 0
@export var mp_cost: int = 0
@export_subgroup("Targeting")
@export var ability_range: int = 1
@export var target_type: target_type_choice = target_type_choice.target_all
@export_subgroup("Damage")
@export var base_damage: int = 0
@export var damage_type: damage_type_choice = damage_type_choice.blunt
@export var skill_used: skill_used_choice = skill_used_choice.strength
signal activated

func get_valid_destinations()->Array[Vector2]:
	if target_type == target_type_choice.target_self:
		return [user.position]
	var destinations: Array[Vector2] = []
	var scale_factor: int = Settings.tile_size
	for x in range(user.position.x-ability_range*scale_factor, user.position.x+ability_range*scale_factor+1, scale_factor):
		for y in range(user.position.y-ability_range*scale_factor, user.position.y+ability_range*scale_factor+1, scale_factor):
			if Vector2(x,y) != user.position:
				if is_destination_valid(Vector2(x, y)):
					destinations.append(Vector2(x, y))
	return destinations

func is_destination_valid(destination: Vector2)->bool:
	var x_dist: float = abs(global_position.x-destination.x)
	var y_dist: float = abs(global_position.y-destination.y)
	var range_factor: float = (x_dist+y_dist)/Settings.tile_size
	return range_factor<=ability_range

func get_target(destination: Vector2)->Node2D:
	return NavMaster.get_obj_at_pos(destination)

func deal_damage(target: Node2D)->void:
	if target != null:
		if target.has_method("damage"):
			var accuracy: int = randi_range(1, 100) + user.star_stats[skill_used_choice.keys()[skill_used]]
			target.call_deferred("damage", self, accuracy, base_damage)

func activate(_destination: Vector2)->void:
	activated.emit()
