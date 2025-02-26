extends Node

var map: GameMap = null
var map_loading: bool = false
var tile_size: int = 64

func request_nav_path(start: Vector2, end: Vector2, allow_closest: bool = true)->Array[Vector2]:
	if map == null || !is_instance_valid(map):
		return []
	return map.get_nav_path(start, end, allow_closest)

func is_pos_occupied(pos: Vector2)->bool:
	if map == null || !is_instance_valid(map):
		return false
	return map.astar.is_point_solid(map.local_to_map(pos))

func get_obj_at_pos(pos: Vector2)->Node2D:
	if map == null || !is_instance_valid(map):
		return null
	return map.get_obj_at_pos(pos)

func is_in_bounds(pos: Vector2)->bool:
	if map == null || !is_instance_valid(map):
		return false
	return map.is_in_bounds(pos)
