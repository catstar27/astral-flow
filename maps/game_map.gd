extends TileMapLayer
class_name GameMap

@export var player_start_pos: Vector2i = Vector2i.ZERO
@export var ost: AudioStreamWAV
@export var battle_theme: AudioStreamWAV
@export var map_name: String
@onready var astar: AStarGrid2D
@onready var light_modulator: CanvasModulate = %LightingModulate
var children_ready_count: int = 0
var loading: bool = false
var player: Player = null
var occupied_tiles: Array[Vector2i]
var tile_bounds: Dictionary = {"x_min": 0, "x_max": 0, "y_min": 0, "y_max": 0}
var to_save: Array[StringName] = [
	"player_start_pos"
]
#region Signals
signal map_saved
signal map_loaded
signal saved(node)
signal loaded(node)
signal child_readied
#endregion

#region Prep
func _ready()->void:
	EventBus.subscribe("TILE_OCCUPIED", self, "set_pos_occupied")
	EventBus.subscribe("TILE_UNOCCUPIED", self, "set_pos_unoccupied")
	EventBus.subscribe("COMBAT_STARTED", self, "start_combat")
	EventBus.subscribe("COMBAT_ENDED", self, "end_combat")

func _extra_setup()->void:
	return

func prep_map()->void:
	occupied_tiles = []
	light_modulator.show()
	_calc_bounds()
	_astar_setup()
	for child in get_children():
		if child is Interactive:
			child.setup()
			if child.collision_active:
				for pos in child.occupied_positions:
					set_pos_occupied(pos)
		elif child is Character:
			if child.active:
				set_pos_occupied(child.position)
				if child is Player:
					player = child
				child.activate(child.position)
	_extra_setup()
	EventBus.broadcast("MAP_LOADED", self)
#endregion

func start_combat()->void:
	EventBus.broadcast("SET_OST", battle_theme)

func end_combat()->void:
	EventBus.broadcast("SET_OST", ost)

#region Pathfinding
func get_obj_at_pos(pos: Vector2)->Node2D:
	for child in get_children():
		if child is Interactive || child is Character:
			if local_to_map(child.position) == local_to_map(pos):
				if child is Interactive:
					if !child.collision_active:
						continue
				return child
	return null

func set_pos_occupied(pos: Vector2)->void:
	var tile: Vector2i = local_to_map(pos)
	if tile not in occupied_tiles:
		occupied_tiles.append(tile)
	astar.set_point_solid(tile, true)

func set_pos_unoccupied(pos: Vector2)->void:
	var tile: Vector2i = local_to_map(pos)
	if tile in occupied_tiles:
		occupied_tiles.remove_at(occupied_tiles.find(tile))
	astar.set_point_solid(tile, false)

func _astar_setup()->void:
	astar = AStarGrid2D.new()
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

func get_nav_path(start_pos: Vector2, end_pos: Vector2, allow_closest: bool = true)->Array[Vector2]:
	var start_cell: Vector2i = local_to_map(start_pos)
	var end_cell: Vector2i = local_to_map(end_pos)
	if astar.is_in_boundsv(start_cell) && astar.is_in_boundsv(end_cell):
		if !astar.is_point_solid(end_cell):
			var path: Array[Vector2i] = astar.get_id_path(start_cell, end_cell, allow_closest)
			var path_localized: Array[Vector2] = []
			for tile in path:
				path_localized.append(map_to_local(tile))
			return path_localized
		elif allow_closest:
			var dist_compare: Callable = (func(a,b): return a.distance_to(start_cell)<b.distance_to(start_cell))
			var neighbors_sorted: Array[Vector2i] = get_surrounding_cells(end_cell)
			neighbors_sorted.sort_custom(dist_compare)
			for cell in neighbors_sorted:
				if get_cell_tile_data(cell) != null:
					if !astar.is_point_solid(cell):
						var path: Array[Vector2i] = astar.get_id_path(start_cell, cell, true)
						var path_localized: Array[Vector2] = []
						for tile in path:
							path_localized.append(map_to_local(tile))
						return path_localized
			return []
	return []

func get_entrance(id: String)->TravelPoint:
	for child in get_children():
		if child is TravelPoint:
			if child.entrance_id == id:
				return child
	return null

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

func is_in_bounds(pos: Vector2)->bool:
	var tile: Vector2i = local_to_map(pos)
	if get_cell_tile_data(tile) == null:
		return false
	return true
#endregion

#region Save and Load
func unload()->void:
	queue_free()

func child_ready(child)->void:
	if loading:
		child.loaded.disconnect(child_ready)
	else:
		child.saved.disconnect(child_ready)
	children_ready_count += 1
	child_readied.emit()

func has_save_data()->bool:
	var filepath: String = SaveLoad.save_file_folder+SaveLoad.slot+'/'+map_name+'/'
	if FileAccess.open(filepath+map_name+".dat", FileAccess.READ) != null:
		return true
	return false

func save_map(filepath: String)->void:
	if !DirAccess.dir_exists_absolute(filepath+map_name):
		DirAccess.make_dir_absolute(filepath+map_name)
	filepath += map_name+'/'
	save_data(filepath)
	children_ready_count = 0
	var children_to_save: int = 0
	for node in get_children():
		if node.is_in_group("LevelSave"):
			if !node.has_method("save_data"):
				printerr("Persistent node"+node.name+"missing save data function")
			children_to_save += 1
			node.saved.connect(child_ready)
			node.save_data(filepath)
	while children_ready_count < children_to_save:
		await child_readied
	map_saved.emit()

func load_map(filepath: String)->void:
	loading = true
	NavMaster.map_loading = true
	filepath += map_name+'/'
	load_data(filepath)
	children_ready_count = 0
	var children_to_load: int = 0
	for node in get_children():
		if node is Player:
			player = node
		if node.is_in_group("LevelSave"):
			if !node.has_method("load_data"):
				printerr("Persistent node"+node.name+"missing load data function")
			children_to_load += 1
			node.loaded.connect(child_ready)
			node.load_data(filepath)
	while children_ready_count < children_to_load:
		await child_readied
	player.position = map_to_local(player_start_pos)
	map_loaded.emit()
	NavMaster.map_loading = false
	loading = false

func save_data(dir: String)->void:
	player_start_pos = local_to_map(player.position)
	var file: FileAccess = FileAccess.open(dir+map_name+".dat", FileAccess.WRITE)
	for var_name in to_save:
		file.store_var(var_name)
		file.store_var(get(var_name))
	file.store_var("END")
	saved.emit(self)

func load_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+map_name+".dat", FileAccess.READ)
	var var_name: String = file.get_var()
	while var_name != "END":
		set(var_name, file.get_var())
		var_name = file.get_var()
	file.close()
	occupied_tiles = []
	light_modulator.show()
	_calc_bounds()
	_astar_setup()
	loaded.emit(self)
#endregion
