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
@export_group("Cutscenes")
@export var cutscenes: Dictionary[String, Cutscene] ## Dictionary of cutscenes and their names
@export var entry_cutscene_name: String ## Cutscene to play when the map is entered the first time
@onready var astar: AStarGrid2D ## Astar pathfinding grid
@onready var light_modulator: CanvasModulate = %LightingModulate ## Modulator for lighting
var modified_tiles: Dictionary[String, Array] ## Dictionary with terrain/position array pairs for updating tilemap
var loading: bool = false ## Whether the map is loading
var occupied_tiles: Dictionary[Vector2i, Node2D] ## Tiles being occupied by an interactive or character
var last_player_pos: Dictionary[String, Vector2] ## Last saved position of player on this map
var entry_cutscene_played: bool = false ## Whether the entry cutscene has played
var cutscene_event_count: int = 0 ## Number of cutscene events being processed
var to_save: Array[StringName] = [ ## Map variables to save
	"player_start_pos",
	"last_player_pos",
	"modified_tiles",
	"entry_cutscene_played",
]
signal cutscene_event_count_lowered ## Emitted when a character finishes a cutscene event
signal map_saved ## Emitted when the entire map is saved
signal map_loaded ## Emitted when the entire map is loaded
signal saved(node: GameMap) ## Emitted when the map's variables are saved
signal loaded(node: GameMap) ## Emitted when the map's variables are loaded

#region Prep
func _ready()->void:
	EventBus.subscribe("TILE_OCCUPIED", self, "set_pos_occupied")
	EventBus.subscribe("TILE_UNOCCUPIED", self, "set_pos_unoccupied")
	EventBus.subscribe("COMBAT_STARTED", self, "start_combat")
	EventBus.subscribe("COMBAT_ENDED", self, "end_combat")
	EventBus.subscribe("MAP_ENTERED", self, "play_entry_cutscene")
	Dialogic.signal_event.connect(process_dialogue_signal)
	_astar_setup()

## Prepares the map by resetting its astar
## Also performs initial operations for its children
func prep_map()->void:
	occupied_tiles = {}
	light_modulator.show()
	_astar_setup()
	for child in get_children():
		if child is Interactive:
			if child.active:
				child.setup()
				child.update_tiles.connect(set_terrain)
				if child.collision_active:
					for pos in child.occupied_positions:
						set_pos_occupied([pos, child])
		elif child is Character:
			if child.active:
				set_pos_occupied([child.position, child])
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
		astar.set_point_solid(cell, !get_cell_tile_data(cell).get_custom_data("traversible"))
#endregion

#region Child Manipulation
## Processes dialogue signals
func process_dialogue_signal(arg)->void:
	if arg is Dictionary:
		for target_name in arg:
			for child in get_children():
				if child is Character && child.display_name == target_name:
					if child.active || arg[target_name] == "activate":
						if arg[target_name] is String && child.has_method(arg[target_name]):
							child.call_deferred(arg[target_name])
				if child is Interactive && child.id == target_name:
					if child.active || arg[target_name] == "activate":
						if arg[target_name] is String && child.has_method(arg[target_name]):
							child.call_deferred(arg[target_name])
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
	if local_to_map(pos) in occupied_tiles.keys():
		return occupied_tiles[local_to_map(pos)]
	return null

## Sets given position to be occupied
func set_pos_occupied(data: Array)->void:
	if data.size() != 2 || data[0] is not Vector2 || data[1] is not Node2D:
		printerr("Attempted to set pos occupied with invalid arguments: "+str(data))
		return
	var tile: Vector2i = local_to_map(data[0])
	occupied_tiles[tile] = data[1]
	astar.set_point_solid(tile, true)

## Sets the given position to be unoccupied
func set_pos_unoccupied(pos: Vector2)->void:
	var tile: Vector2i = local_to_map(pos)
	if tile in occupied_tiles:
		occupied_tiles[tile] = null
	astar.set_point_solid(tile, false)

## Given a starting and ending position, returns a path between them.
## If allow_closest is true, it will find the nearest valid tile if the end position is occupied.
func get_nav_path(start_pos: Vector2, end_pos: Vector2, allow_closest: bool = true)->Array[Vector2]:
	var start_cell: Vector2i = local_to_map(start_pos)
	var end_cell: Vector2i = local_to_map(end_pos)
	if astar.is_in_boundsv(start_cell) && astar.is_in_boundsv(end_cell):
		if allow_closest && astar.is_point_solid(end_cell):
			end_cell = get_nearest_empty_tile(start_cell, end_cell)
		var path: Array[Vector2i] = astar.get_id_path(start_cell, end_cell, allow_closest)
		var path_localized: Array[Vector2] = []
		for tile in path:
			path_localized.append(map_to_local(tile))
		return path_localized
	return []

## Uses bfs to find the nearest empty tile
func get_nearest_empty_tile(origin: Vector2i, pos: Vector2i)->Vector2i:
	var visited: Dictionary[Vector2i, bool]
	visited[pos] = true
	var queue: Array[Vector2i]
	queue.push_front(pos)
	while queue != []:
		var cur_pos: Vector2i = queue.pop_front()
		if get_cell_tile_data(cur_pos) != null && !astar.is_point_solid(cur_pos):
			var best_distance: float = (cur_pos-origin).length()+1000*(pos-cur_pos).length()
			for tile in queue:
				if !astar.is_point_solid(tile):
					if ((tile-origin).length()+1000*(pos-tile).length()) <= best_distance:
						best_distance = (tile-origin).length()+1000*(pos-tile).length()
						cur_pos = tile
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

#region Cutscenes
## Plays the entry cutscene
func play_entry_cutscene(_map: String = "")->void:
	if !entry_cutscene_played:
		play_cutscene(entry_cutscene_name)

## Plays the cutscene with the given name
func play_cutscene(cutscene_name: String)->void:
	if cutscene_name not in cutscenes:
		return
	EventBus.broadcast("CUTSCENE_STARTED", "NULLDATA")
	var cutscene: Cutscene = cutscenes[cutscene_name]
	for stage in cutscene.cutscene_stages:
		for event in stage.cutscene_events:
			if event is CursorCutsceneEvent:
				find_child("SelectionCursor").position = event.position
			elif event is CharacterCutsceneEvent:
				var target: Character = find_child(event.target_name, true, false)
				if target == null:
					printerr("Missing Cutscene Target '"+event.target_name+"'")
					continue
				target.cutscene_event_processed.connect(cutscene_event_count_decrease)
				cutscene_event_count += 1
				target.process_cutscene_event(event)
			elif event is WaitCutsceneEvent:
				cutscene_event_count += 1
				await get_tree().create_timer(event.time).timeout
				cutscene_event_count_decrease(null)
			elif event is DialogueCutsceneEvent:
				cutscene_event_count += 1
				EventBus.broadcast("ENTER_DIALOGUE", [event.dialogue, event.pause_music])
				await Dialogic.timeline_ended
				cutscene_event_count_decrease(null)
		while cutscene_event_count != 0:
			await cutscene_event_count_lowered
	EventBus.broadcast("CUTSCENE_ENDED", "NULLDATA")

## Decrements cutscene_event_count
func cutscene_event_count_decrease(source: Character)->void:
	cutscene_event_count -= 1
	if source != null:
		source.cutscene_event_processed.disconnect(cutscene_event_count_decrease)
	cutscene_event_count_lowered.emit()
#endregion

#region Tile Manipulation
## Updates the tiles with given terrain
func set_terrain(cells: Array, terrain: String)->void:
	var terrain_idx: int = -1
	for n in range(0, tile_set.get_terrains_count(0)):
		if tile_set.get_terrain_name(0, n) == terrain:
			terrain_idx = n
			break
	if terrain_idx == -1:
		printerr("Invalid Terrain "+terrain)
		return
	set_cells_terrain_connect(cells, 0, terrain_idx)
	for cell in cells:
		astar.set_point_solid(cell, !get_cell_tile_data(cell).get_custom_data("traversible"))
	modified_tiles[terrain] = cells
#endregion

#region Save and Load
## Gets save data for this map and all its saved children
func get_save_data()->Dictionary[String, Dictionary]:
	var dict: Dictionary[String, Dictionary]
	var self_dict: Dictionary[String, Variant]
	for node in get_children():
		if node is Player:
			last_player_pos[node.name] = node.position
	for value in to_save:
		self_dict[value] = get(value)
	dict[name] = self_dict
	for node in get_children():
		if node.is_in_group("LevelSave"):
			node.pre_save()
			var node_dict: Dictionary[String, Variant]
			for value in node.to_save:
				node_dict[value] = node.get(value)
			dict[node.name] = node_dict
			node.post_save()
	map_saved.emit()
	saved.emit(self)
	return dict

## Loads save data for this map and all its saved children
func load_save_data(dict: Dictionary[String, Dictionary])->void:
	loading = true
	NavMaster.map_loading = true
	_astar_setup()
	if name in dict:
		var self_dict: Dictionary[String, Variant] = dict[name]
		for value in self_dict:
			set(value, self_dict[value])
	for terrain in modified_tiles:
		set_terrain(modified_tiles[terrain], terrain)
	for node in get_children():
		if node.is_in_group("LevelSave") && node.name in dict:
			var node_dict: Dictionary[String, Variant] = dict[node.name]
			node.pre_load()
			for value in node_dict:
				node.set(value, node_dict[value])
			node.post_load()
	NavMaster.map_loading = false
	loading = false
	map_loaded.emit()
	loaded.emit(self)
#endregion
