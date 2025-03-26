extends Node2D
class_name TextIndicator
## Indicator that displays text, plays an animation, and deletes itself

@onready var indicator_label: RichTextLabel = %TextIndicatorLabel ## Text label for the indicator
var text: String = "" ## Text to put in label
var color: Color = Color.WHITE ## Color of text in label

func _ready()->void:
	indicator_label.text = "[center]"+text+"[/center]"
	indicator_label.modulate = color
	create_tween().tween_property(indicator_label, "position", indicator_label.position+Vector2.UP*128, 1)\
	.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	await get_tree().create_timer(.5).timeout
	await create_tween().tween_property(self, "modulate", Color.TRANSPARENT, .5).finished
	queue_free()
