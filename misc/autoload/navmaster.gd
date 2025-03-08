extends Node
## Autoload that allows accessing the current map across the program

var map: GameMap = null ## The current map
var map_loading: bool = false ## Whether the map is loading
var tile_size: int = 64 ## The size of map tiles in pixels

## Requests a nav path from the current map; returns an array of positions or an empty array if there is no map
func request_nav_path(start: Vector2, end: Vector2, allow_closest: bool = true)->Array[Vector2]:
	if map == null || !is_instance_valid(map):
		return []
	return map.get_nav_path(start, end, allow_closest)

## Checks whether a given position is occupied; returns false always if the map is invalid
func is_pos_occupied(pos: Vector2)->bool:
	if map == null || !is_instance_valid(map):
		return false
	return map.astar.is_point_solid(map.local_to_map(pos))

## Gets an object at given position; returns null always if the map is invalid
func get_obj_at_pos(pos: Vector2)->Node2D:
	if map == null || !is_instance_valid(map):
		return null
	return map.get_obj_at_pos(pos)

## Returns array of surrounding tile positions
func get_pos_tile_neighbors(pos: Vector2)->Array[Vector2]:
	var neighbors: Array[Vector2i] = map.get_surrounding_cells(map.local_to_map(pos))
	var positions: Array[Vector2] = []
	for tile in neighbors:
		positions.append(map.map_to_local(tile))
	return positions

## Checks whether a given position is in the map bounds; returns false always if the map is invalid
func is_in_bounds(pos: Vector2)->bool:
	if map == null || !is_instance_valid(map):
		return false
	return map.is_in_bounds(pos)
