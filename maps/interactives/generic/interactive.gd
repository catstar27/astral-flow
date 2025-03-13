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
@onready var sprite: Sprite2D = %Sprite ## Sprite of the interactive
@onready var collision: CollisionShape2D = %Collision ## Collision of the interactive
var collision_active: bool = true ## Whether the collision is active
var occupied_positions: Array[Vector2] ## Positions occupied by the interactive
var dialogue_timeline: DialogicTimeline = null ## Timeline of dialogue loaded during setup
var allow_dialogue: bool = true ## Whether the dialogue should be played when interacted
signal interacted ## Emitted when interacted with

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
	if character is Player:
		EventBus.broadcast("QUEST_EVENT", "interact_with:"+id)
	if interact_sfx != null && !SaveLoad.loading && !NavMaster.map_loading:
		EventBus.broadcast("PLAY_SOUND", [interact_sfx, "positional", global_position])
	if dialogue_timeline != null && character is Player && allow_dialogue:
		EventBus.broadcast("ENTER_DIALOGUE", [dialogue_timeline, pause_music])
	_interact_extra(character)
	interacted.emit()

## Called after the base class interact function
func _interact_extra(_character: Character)->void:
	return
