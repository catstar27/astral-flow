extends StaticBody2D
class_name Interactive

@export var dialogue: String
@export var texture: Texture
@export var dimensions: Vector2i = Vector2i.ONE
@onready var sprite: Sprite2D = %Sprite
@onready var audio: AudioStreamPlayer2D = %Audio
@onready var collision: CollisionShape2D = %Collision
var occupied_tiles: Array[Vector2i]
var dialogue_timeline: DialogicTimeline = null
signal interacted

func setup()->void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = 64*Vector2(float(dimensions.x)/scale.x, float(dimensions.y)/scale.y)
	collision.shape = shape
	sprite.texture = texture
	if dialogue != "":
		dialogue_timeline = load(dialogue)
	_calc_occupied()

func _calc_occupied()->void:
	for x in range(0, dimensions.x):
		for y in range(0, dimensions.y):
			occupied_tiles.append(GlobalRes.map.local_to_map(position)+Vector2i(-x, y))

func _interacted(_character: Character)->void:
	audio.play()
	if dialogue_timeline != null:
		GlobalRes.current_timeline = Dialogic.start(dialogue_timeline)
	interacted.emit()
