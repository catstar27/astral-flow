extends StaticBody2D
class_name Interactive

@export var dialogue: String
@export var texture: Texture
@onready var sprite: Sprite2D = %Sprite
@onready var audio: AudioStreamPlayer2D = %Audio
@onready var collision: CollisionShape2D = %Collision
var dialogue_timeline: DialogicTimeline = null
signal interacted

func _ready() -> void:
	_setup()

func _setup()->void:
	sprite.texture = texture
	if dialogue != "":
		dialogue_timeline = load(dialogue)

func _interacted(_character: Character):
	audio.play()
	if dialogue_timeline != null:
		Dialogic.start(dialogue_timeline)
	interacted.emit()
