extends TileMapLayer
class_name GameMap
## Custom tilemap representing a map in the game
##
## Contains all necessary pathfinding functions,
## as well as the ability to save map-specific nodes

 ## Position for player to start if not coming from an entrance
@export var player_start_pos: Vector2i = Vector2i.ZERO
@export var calm_theme: AudioStreamWAV ## Theme to play outside combat
@export var battle_theme: AudioStreamWAV ## Theme to play in combat
@export var map_name: String ## Display name of map
@onready var astar: AStarGrid2D ## Astar pathfinding grid
@onready var light_modulator: CanvasModulate = %LightingModulate ## Modulator for lighting
var children_ready_count: int = 0 ## Number of children saved/loaded
var loading: bool = false ## Whether the map is loading
var player: Player = null ## The player node
var occupied_tiles: Array[Vector2i] ## Tiles being occupied by an interactive or character
var to_save: Array[StringName] = [ ## Map variables to save
	"player_start_pos"
]
signal map_saved ## Emitted when the entire map is saved
signal map_loaded ## Emitted when the entire map is loaded
signal saved(node: GameMap) ## Emitted when the map's variables are saved
signal loaded(node: GameMap) ## Emitted when the map's variables are loaded
signal child_readied ## Emitted when a child of the map has saved/loaded

#region Prep
func _ready()->void:
	EventBus.subscribe("TILE_OCCUPIED", self, "set_pos_occupied")
	EventBus.subscribe("TILE_UNOCCUPIED", self, "set_pos_unoccupied")
	EventBus.subscribe("COMBAT_STARTED", self, "start_combat")
	EventBus.subscribe("COMBAT_ENDED", self, "end_combat")

## Prepares the map by resetting its astar
## Also performs initial operations for its children
func prep_map()->void:
	occupied_tiles = []
	light_modulator.show()
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
	EventBus.broadcast("MAP_LOADED", self)

## Preps the astar grid, configuring its settings
func _astar_setup()->void:
	astar = AStarGrid2D.new()
	astar.region = get_used_rect()
	astar.cell_size = tile_set.tile_size
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	_set_astar_tiles()

## Sets all tiles not marked as traversible to solid
func _set_astar_tiles()->void:
	for cell in get_used_cells():
		if !get_cell_tile_data(cell).get_custom_data("traversible"):
			astar.set_point_solid(cell)
#endregion

#region Combat
## Called at the start of combat to start the battle theme
func start_combat()->void:
	EventBus.broadcast("SET_OST", battle_theme)

## Called after combat ends to return to the calm theme
func end_combat()->void:
	EventBus.broadcast("SET_OST", calm_theme)
#endregion

#region Pathfinding
## Finds and returns the object at given position, or null if there is none
func get_obj_at_pos(pos: Vector2)->Node2D:
	for child in get_children():
		if child is Interactive || child is Character:
			if local_to_map(child.position) == local_to_map(pos):
				if child is Interactive:
					if !child.collision_active:
						continue
				return child
	return null

## Sets given position to be occupied
func set_pos_occupied(pos: Vector2)->void:
	var tile: Vector2i = local_to_map(pos)
	if tile not in occupied_tiles:
		occupied_tiles.append(tile)
	astar.set_point_solid(tile, true)

## Sets the given position to be unoccupied
func set_pos_unoccupied(pos: Vector2)->void:
	var tile: Vector2i = local_to_map(pos)
	if tile in occupied_tiles:
		occupied_tiles.remove_at(occupied_tiles.find(tile))
	astar.set_point_solid(tile, false)

## Given a starting and ending position, returns a path between them.
## If allow_closest is true, it will find the nearest valid tile if the
## end position is occupied.
func get_nav_path(start_pos: Vector2, end_pos: Vector2, allow_closest: bool = true)->Array[Vector2]:
	var start_cell: Vector2i = local_to_map(start_pos)
	var end_cell: Vector2i = local_to_map(end_pos)
	if astar.is_in_boundsv(start_cell) && astar.is_in_boundsv(end_cell):
		if allow_closest && astar.is_point_solid(end_cell):
			end_cell = get_nearest_empty_tile(end_cell)
		var path: Array[Vector2i] = astar.get_id_path(start_cell, end_cell, allow_closest)
		var path_localized: Array[Vector2] = []
		for tile in path:
			path_localized.append(map_to_local(tile))
		return path_localized
	return []

## Uses bfs to find the nearest empty tile
func get_nearest_empty_tile(pos: Vector2i)->Vector2i:
	var visited: Dictionary[Vector2i, bool]
	visited[pos] = true
	var queue: Array[Vector2i]
	queue.push_front(pos)
	while queue != []:
		var cur_pos: Vector2i = queue.pop_front()
		if get_cell_tile_data(cur_pos) != null && !astar.is_point_solid(cur_pos):
			return cur_pos
		for cell in get_surrounding_cells(cur_pos):
			if cell not in visited:
				visited[cell] = false
			if get_cell_tile_data(cell) != null && !visited[cell]:
				visited[cell] = true
				queue.push_back(cell)
	printerr("No Empty Tile in Map!")
	return pos

## Returns an entrance that has given id
func get_entrance(id: String)->TravelPoint:
	for child in get_children():
		if child is TravelPoint:
			if child.entrance_id == id:
				return child
	return null

## Determines if given position is in the map bounds
func is_in_bounds(pos: Vector2)->bool:
	var tile: Vector2i = local_to_map(pos)
	if get_cell_tile_data(tile) == null:
		return false
	return true
#endregion

#region Save and Load
## Called when a child finishes saving/loading
func child_ready(child)->void:
	if loading:
		child.loaded.disconnect(child_ready)
	else:
		child.saved.disconnect(child_ready)
	children_ready_count += 1
	child_readied.emit()

## Checks whether the map has save data
func has_save_data()->bool:
	var filepath: String = SaveLoad.save_file_folder+SaveLoad.slot+'/'+map_name+'/'
	if FileAccess.open(filepath+map_name+".dat", FileAccess.READ) != null:
		return true
	return false

## Saves the entire map and all its children
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

## Loads the entire map and all its children
func load_map(filepath: String)->void:
	loading = true
	NavMaster.map_loading = true
	if astar == null:
		_astar_setup()
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
	map_loaded.emit()
	NavMaster.map_loading = false
	loading = false

## Saves map variables
func save_data(dir: String)->void:
	player_start_pos = local_to_map(player.position)
	var file: FileAccess = FileAccess.open(dir+map_name+".dat", FileAccess.WRITE)
	for var_name in to_save:
		file.store_var(var_name)
		file.store_var(get(var_name))
	file.store_var("END")
	saved.emit(self)

## Loads map variables
func load_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+map_name+".dat", FileAccess.READ)
	var var_name: String = file.get_var()
	while var_name != "END":
		set(var_name, file.get_var())
		var_name = file.get_var()
	file.close()
	loaded.emit(self)
#endregion
