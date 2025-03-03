extends Node2D
class_name TextIndicator
## Indicator that displays text, plays an animation, and deletes itself

@onready var anim_player: AnimationPlayer = %AnimationPlayer ## Animation player for the indicator
@onready var indicator_label: RichTextLabel = %TextIndicatorLabel ## Text label for the indicator
var text: String = "" ## Text to put in label
var color: Color = Color.WHITE ## Color of text in label

func _ready()->void:
	indicator_label.text = "[center]"+text+"[/center]"
	indicator_label.modulate = color
	anim_player.play("upward_fade")

## Called to end the animation by deleting this
func end()->void:
	queue_free()
