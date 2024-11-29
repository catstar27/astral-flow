extends StaticBody2D
class_name Interactive

@export var dialogue: String
@export var texture: Texture
@export var dimensions: Vector2i = Vector2i.ONE
@export var offset: Vector2 = Vector2.ZERO
@export var pause_music: bool = false
@onready var sprite: Sprite2D = %Sprite
@onready var audio: AudioStreamPlayer2D = %Audio
@onready var collision: CollisionShape2D = %Collision
var occupied_positions: Array[Vector2]
var dialogue_timeline: DialogicTimeline = null
signal interacted

func setup()->void:
	collision.scale = Vector2(float(dimensions.x)/scale.x, float(dimensions.y)/scale.y)
	_calc_occupied()
	var shift_pos: Vector2 = get_middle(occupied_positions) - position
	collision.position = shift_pos
	sprite.position = shift_pos
	if texture != null:
		sprite.texture = texture
	if offset != Vector2.ZERO:
		sprite.offset = offset
	if dialogue != "":
		dialogue_timeline = load(dialogue)

func get_middle(positions: Array[Vector2])->Vector2:
	var sum: Vector2 = Vector2.ZERO
	for pos in positions:
		sum += pos
	sum /= positions.size()
	return sum

func _calc_occupied()->void:
	if dimensions == Vector2i.ONE:
		occupied_positions = [position]
		return
	for x in range(0, dimensions.x):
		for y in range(0, dimensions.y):
			var x_scaled: int = x*Settings.tile_size
			var y_scaled: int = y*Settings.tile_size
			occupied_positions.append(position+Vector2(x_scaled, y_scaled))

func _interacted(_character: Character)->void:
	audio.play()
	if dialogue_timeline != null:
		EventBus.broadcast(EventBus.Event.new("ENTER_DIALOGUE", [dialogue_timeline, pause_music]))
	interacted.emit()
