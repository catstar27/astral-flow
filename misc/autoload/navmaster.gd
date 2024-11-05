extends Node

var _map: GameMap = null

func _ready() -> void:
	EventBus.subscribe("MAP_LOADED", self, "_set_map")

func _set_map(map: GameMap)->void:
	_map = map

func request_nav_path(start: Vector2, end: Vector2, allow_closest: bool = true)->Array[Vector2]:
	if _map == null || !is_instance_valid(_map):
		return []
	return _map.get_nav_path(start, end, allow_closest)

func is_pos_occupied(pos: Vector2)->bool:
	if _map == null || !is_instance_valid(_map):
		return false
	return _map.local_to_map(pos) in _map.occupied_tiles

func get_obj_at_pos(pos: Vector2)->Node2D:
	if _map == null || !is_instance_valid(_map):
		return null
	return _map.get_obj_at_pos(pos)

func is_in_bounds(pos: Vector2)->bool:
	if _map == null || !is_instance_valid(_map):
		return false
	return _map.is_in_bounds(pos)
