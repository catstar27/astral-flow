extends VBoxContainer
class_name StatusDisplay
## Simple display that shows a status

@onready var duration_label: Label = %DurationLabel ## Label showing status duration
@onready var stack_label: Label = %StackLabel ## Label showing status stacks
@onready var icon: TextureRect = %Icon ## Texture rect showing status icon

## Changes the display to match the given status
func display_status(status: Status, stacks: int, duration: int)->void:
	show()
	if status.time_choice != status.time_options.timed:
		duration_label.text = "⧖∞"
	else:
		duration_label.text = "⧖"+str(duration)
	stack_label.text = "x"+str(stacks)
	icon.texture = status.icon
