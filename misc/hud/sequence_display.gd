extends Control
class_name SequenceDisplay
## Displays the sequence of characters in combat

@onready var anim: AnimationPlayer = %AnimationPlayer ## Animates the display
@onready var panels: Array[PanelContainer] = [ ## Containers holding the labels for each character
	%PanelContainer,
	%PanelContainer2,
	%PanelContainer3,
	%PanelContainer4
]
var current_index: int = 0 ## Index of the panel that matches the current character
var current_order: Array[Character] = [] ## Order of the turn this is tracking
var is_updating: bool = false ## Whether the display is currently updating

func _ready()->void:
	EventBus.subscribe("SEQUENCE_UPDATED", self, "update_order")
	EventBus.subscribe("ROUND_STARTED", self, "update_order")
	EventBus.subscribe("TURN_ENDED", self, "cycle_display")
	EventBus.subscribe("COMBAT_ENDED", self, "hide")

## Updates the order of sequence and shows the display
func update_order(order: Array[Character])->void:
	current_order = order.duplicate()
	await update_display(true)

## Updates the text of the panels
func update_display(play_animation: bool = false)->void:
	while anim.is_playing():
		await anim.animation_finished
	anim.play("RESET")
	is_updating = true
	if play_animation:
		print(position)
		await create_tween().tween_property(self, "position", position+200*Vector2.RIGHT, .5).finished
		hide()
	if current_index == 0:
		panels[3].get_children()[0].text = "---"
	else:
		panels[3].get_children()[0].text = current_order[current_index-1].display_name
	panels[2].get_children()[0].text = current_order[current_index].display_name
	if current_order.size() > current_index+1:
		panels[1].get_children()[0].text = current_order[current_index+1].display_name
		if current_order.size() > current_index+2:
			panels[0].get_children()[0].text = current_order[current_index+2].display_name
		else:
			panels[0].get_children()[0].text = "END"
	else:
		panels[1].get_children()[0].text = "END"
		panels[0].get_children()[0].text = "---"
	if play_animation:
		show()
		await create_tween().tween_property(self, "position", position+200*Vector2.LEFT, .5).finished
		EventBus.broadcast("SEQUENCE_DISPLAY_CYCLED", "NULLDATA")
	is_updating = false

## Moves the panels so that the current character is pointed at
func cycle_display()->void:
	current_index += 1
	anim.play("cycle")

## Resets the panel positions and shifts the text after the animation plays
func end_cycle()->void:
	anim.play("RESET")
	if current_index != current_order.size():
		await update_display()
	else:
		current_index = 0
	EventBus.broadcast("SEQUENCE_DISPLAY_CYCLED", "NULLDATA")
