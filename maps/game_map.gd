extends TileMapLayer
class_name GameMap

@export var player_start_pos: Vector2i = Vector2i.ZERO
@onready var astar: AStarGrid2D = AStarGrid2D.new()
@onready var light_modulator: CanvasModulate = %LightingModulate
var tile_bounds: Dictionary = {"x_min": 0, "x_max": 0, "y_min": 0, "y_max": 0}

func update_occupied_tiles(tile: Vector2i, occupied: bool = false)->void:
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

func get_nav_path(start_pos: Vector2, end_pos: Vector2, allow_closest: bool = true)->Array[Vector2i]:
	var start_cell: Vector2i = local_to_map(start_pos)
	var end_cell: Vector2i = local_to_map(end_pos)
	if astar.is_in_boundsv(start_cell) && astar.is_in_boundsv(end_cell):
		if !astar.is_point_solid(end_cell):
			return astar.get_id_path(start_cell, end_cell, allow_closest)
		elif allow_closest:
			var dist_compare: Callable = (func(a,b): return a.distance_to(start_cell)<b.distance_to(start_cell))
			var neighbors_sorted: Array[Vector2i] = get_surrounding_cells(end_cell)
			neighbors_sorted.sort_custom(dist_compare)
			for cell in neighbors_sorted:
				if !astar.is_point_solid(cell):
					return astar.get_id_path(start_cell, cell, true)
			return []
	return []

func _calc_bounds()->void:
	var cells: Array[Vector2i] = get_used_cells()
	for cell in cells:
		if cell.x<tile_bounds.x_min:
			tile_bounds.x_min = cell.x
		if cell.x>tile_bounds.x_max:
			tile_bounds.x_max = cell.x
		if cell.y<tile_bounds.y_min:
			tile_bounds.y_min = cell.y
		if cell.y>tile_bounds.y_max:
			tile_bounds.y_max = cell.y

func is_in_bounds(pos: Vector2i)->bool:
	if pos.x<tile_bounds.x_min || pos.x>tile_bounds.x_max:
		return false
	if pos.y<tile_bounds.y_min || pos.y>tile_bounds.y_max:
		return false
	return true

func prep_map()->void:
	light_modulator.show()
	_calc_bounds()
	_astar_setup()
	for child in get_children():
		if child is Interactive:
			child.setup()
			for tile in child.occupied_tiles:
				update_occupied_tiles(tile, true)
		elif child is CanvasModulate:
			pass
		else:
			update_occupied_tiles(local_to_map(child.position), true)
