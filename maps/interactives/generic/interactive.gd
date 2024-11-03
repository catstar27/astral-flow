extends StaticBody2D
class_name Interactive

@export var dialogue: String
@export var texture: Texture
@export var dimensions: Vector2i = Vector2i.ONE
@export var offset: Vector2 = Vector2.ZERO
@onready var sprite: Sprite2D = %Sprite
@onready var audio: AudioStreamPlayer2D = %Audio
@onready var collision: CollisionShape2D = %Collision
var occupied_positions: Array[Vector2]
var dialogue_timeline: DialogicTimeline = null
signal interacted

func setup()->void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = 64*Vector2(float(dimensions.x)/scale.x, float(dimensions.y)/scale.y)
	collision.shape = shape
	if texture != null:
		sprite.texture = texture
	if offset != Vector2.ZERO:
		sprite.offset = offset
	if dialogue != "":
		dialogue_timeline = load(dialogue)
	_calc_occupied()

func _calc_occupied()->void:
	for x in range(0, dimensions.x):
		for y in range(0, dimensions.y):
			var x_scaled: int = x*Settings.tile_size
			var y_scaled: int = y*Settings.tile_size
			occupied_positions.append(position+Vector2(-x_scaled, y_scaled))

func _interacted(_character: Character)->void:
	audio.play()
	if dialogue_timeline != null:
		EventBus.broadcast(EventBus.Event.new("ENTER_DIALOGUE", dialogue_timeline))
	interacted.emit()
