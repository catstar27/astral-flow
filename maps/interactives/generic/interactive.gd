@tool
extends StaticBody2D
class_name Interactive
## Base interactive class that represents objects that can be interacted with
##
## Has functions that trigger on interaction
## Can be a variety of sizes, taking up any number of tiles
## Can function on its own for simple dialogue triggers

@export var id: String = ""## Name for this interactive (for quest purposes)
@export var texture: Texture2D: ## Texture of the interactive
	set(tex):
		texture = tex
		%Sprite.texture = tex
@export var dimensions: Vector2i = Vector2i.ONE: ## Dimensions of the interactive
	set(dim):
		dimensions = dim
		calc_size_properties()
@export var offset: Vector2 = Vector2.ZERO: ## Offset of the interactive's sprite
	set(new_offset):
		offset = new_offset
		$Sprite.offset = new_offset
@export var interact_sfx: AudioStreamWAV ## Sound to play when interacted with
@export_group("Dialogic") ## Variables related to dialogue
@export var dialogue: DialogicTimeline ## Dialogue to play when this is interacted with
@export var pause_music: bool = false ## Whether this pauses music in dialogue
@export_group("Tile Manipulation") ## Variables related to changing tiles in the map
@export_storage var tile_changes_terrain: Dictionary[String, Array] ## Collects same terrain sets together
@export var tile_range: Array[Vector2i] ## Range of tiles to add to tile_changes
@export var range_terrain: String ## Terrain to use for this range
@export_tool_button("Add Range") var add_range_fn = add_range ## Adds the current ranges
@export var tile_changes: Dictionary[Vector2i, String] = {}: ## Tiles to change when interacted with
	set(new_tc):
		tile_changes = new_tc
		update_tile_changes()
@export_group("Activation")
@export var active: bool = true ## Whether this interactive is part of the game map currently
@onready var sprite: Sprite2D = %Sprite ## Sprite of the interactive
@onready var collision: CollisionShape2D = %Collision ## Collision of the interactive
var collision_active: bool = true ## Whether the collision is active
var occupied_positions: Array[Vector2] ## Positions occupied by the interactive
var dialogue_timeline: DialogicTimeline = null ## Timeline of dialogue loaded during setup
var allow_dialogue: bool = true ## Whether the dialogue should be played when interacted
var to_save: Array[StringName] = [ ## Variables to save
	"active",
]
signal saved(node: Interactive) ## Emitted when saved
signal loaded(node: Interactive) ## Emitted when loaded
signal interacted ## Emitted when interacted with
signal interacted_id(id: String) ## Emitted when interacted with, with id as arg
signal update_tiles(tiles: Array, terrain: String) ## Updates game map with terrains and position
signal updated_tiles ## Emitted when update_tiles is, does not contain args
signal updated_tiles_named(id: String) ## Emitted when update_tiles is, giving the id of this

## Sets up the interactive, scaling it properly and setting its position
func setup()->void:
	calc_size_properties()
	if dialogue != null:
		dialogue_timeline = dialogue
	setup_extra()

## Called after base class setup
func setup_extra()->void:
	return

func calc_size_properties()->void:
	$Collision.scale = Vector2(float(dimensions.x)/scale.x, float(dimensions.y)/scale.y)
	_calc_occupied()
	var shift_pos: Vector2 = get_middle(occupied_positions) - position
	$Collision.position = shift_pos
	$Sprite.position = shift_pos

## Gets the middle of the given positions
func get_middle(positions: Array[Vector2])->Vector2:
	var sum: Vector2 = Vector2.ZERO
	for pos in positions:
		sum += pos
	sum /= positions.size()
	return sum

## Calculates occupied positions of this interactive
func _calc_occupied()->void:
	if dimensions == Vector2i.ONE:
		occupied_positions = [position]
		return
	for x in range(0, dimensions.x):
		for y in range(0, dimensions.y):
			var x_scaled: int = x*64
			var y_scaled: int = y*64
			occupied_positions.append(position+Vector2(x_scaled, y_scaled))

## Called when this interactive is interacted with
func _interacted(character: Character)->void:
	if character.is_in_group("PartyMember"):
		EventBus.broadcast("QUEST_EVENT", "interact_with:"+id)
	if interact_sfx != null && !SaveLoad.loading && !NavMaster.map_loading:
		EventBus.broadcast("PLAY_SOUND", [interact_sfx, "positional", global_position])
	if dialogue_timeline != null && character.is_in_group("PartyMember") && allow_dialogue:
		EventBus.broadcast("ENTER_DIALOGUE", [dialogue_timeline, pause_music])
	_interact_extra(character)
	interacted.emit()
	interacted_id.emit(id)

## Activates the interactive
func activate()->void:
	calc_size_properties()
	active = true
	collision.set_deferred("disabled", !collision_active)
	if collision_active:
		EventBus.broadcast("TILE_OCCUPIED", [position, self])
	show()

## Deactivates the interactive
func deactivate()->void:
	active = false
	collision.set_deferred("disabled", true)
	EventBus.broadcast("TILE_UNOCCUPIED", position)
	hide()

## Emits the update_tiles signal
func emit_update_tiles()->void:
	for terrain in tile_changes_terrain:
		update_tiles.emit(tile_changes_terrain[terrain], terrain)
	updated_tiles.emit()
	updated_tiles_named.emit(id)

## Called after the base class interact function
func _interact_extra(_character: Character)->void:
	return

## Updates tile_changes_terrains
func update_tile_changes()->void:
	tile_changes_terrain.clear()
	for tile in tile_changes:
		if tile_changes[tile] not in tile_changes_terrain:
			tile_changes_terrain[tile_changes[tile]] = []
		tile_changes_terrain[tile_changes[tile]].append(tile)

## Adds the range into tile updates
func add_range()->void:
	var i1: int = 0
	var i2: int = 1
	while i2 < tile_range.size():
		var x_start: int = tile_range[i1].x
		var x_end: int = tile_range[i2].x
		var y_start: int = tile_range[i1].y
		var y_end: int = tile_range[i2].y
		if tile_range[i1].x > tile_range[i2].x:
			x_start = tile_range[i2].x
			x_end = tile_range[i1].x
		if tile_range[i1].y > tile_range[i2].y:
			y_start = tile_range[i2].y
			y_end = tile_range[i1].y
		for x in range(x_start, x_end+1):
			for y in range(y_start, y_end+1):
				tile_changes[Vector2i(x,y)] = range_terrain
		i1 += 1
		i2 += 1
	range_terrain = ""
	tile_range.clear()
	notify_property_list_changed()

#region Save and Load
## Executes before making the save dict
func pre_save()->void:
	return

## Executes after making the save dict
func post_save()->void:
	saved.emit(self)

## Executes before loading data
func pre_load()->void:
	return

## Executes after loading data
func post_load()->void:
	if active:
		activate()
	else:
		deactivate()
	loaded.emit(self)
#endregion
