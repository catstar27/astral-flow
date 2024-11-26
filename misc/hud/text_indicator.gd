extends Node2D
class_name TextIndicator

@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var indicator_label: RichTextLabel = %TextIndicatorLabel
var text: String = ""
var color: Color = Color.WHITE

func _ready()->void:
	indicator_label.text = "[center]"+text+"[/center]"
	indicator_label.modulate = color
	anim_player.play("upward_fade")

func end()->void:
	queue_free()
