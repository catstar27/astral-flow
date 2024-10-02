extends TileMapLayer
class_name GameMap

@export var player_start_pos: Vector2i = Vector2i.ZERO
@onready var astar: AStarGrid2D = AStarGrid2D.new()

func update_occupied_tiles(tile: Vector2i, occupied: bool = false)->void:
	print(tile)
	astar.set_point_solid(tile, occupied)

func _astar_setup()->void:
	astar.region = get_used_rect()
	astar.cell_size = tile_set.tile_size
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	_set_astar_tiles()

func _set_astar_tiles()->void:
	for cell in get_used_cells():
		if !get_cell_tile_data(cell).get_custom_data("traversible"):
			astar.set_point_solid(cell)

func get_nav_path(start_pos: Vector2, end_pos: Vector2)->Array[Vector2i]:
	var start_cell: Vector2i = local_to_map(start_pos)
	var end_cell: Vector2i = local_to_map(end_pos)
	if astar.is_in_boundsv(start_cell) && astar.is_in_boundsv(end_cell):
		return astar.get_id_path(start_cell, end_cell, true)
	return []

func prep_map()->void:
	_astar_setup()
	for child in get_children():
		update_occupied_tiles(local_to_map(child.position), true)
