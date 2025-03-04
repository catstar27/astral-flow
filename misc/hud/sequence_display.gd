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

func _ready()->void:
	EventBus.subscribe("ROUND_STARTED", self, "update_display")
	EventBus.subscribe("TURN_ENDED", self, "cycle_display")
	EventBus.subscribe("COMBAT_ENDED", self, "hide")

## Sets the text of the panels
func update_display(order: Array[Character])->void:
	show()
	current_order = order
	panels[3].get_children()[0].text = "---"
	panels[2].get_children()[0].text = order[0].display_name
	panels[1].get_children()[0].text = order[1].display_name
	if order.size() > 2:
		panels[0].get_children()[0].text = order[2].display_name
	else:
		panels[0].get_children()[0].text = "END"

## Moves the panels so that the current character is pointed at
func cycle_display()->void:
	current_index += 1
	anim.play("cycle")

## Resets the panels when reaching the end of the cycle
func end_cycle()->void:
	var panel4_prev_text: String = panels[3].get_children()[0].text
	panels[3].get_children()[0].text = panels[2].get_children()[0].text
	panels[2].get_children()[0].text = panels[1].get_children()[0].text
	panels[1].get_children()[0].text = panels[0].get_children()[0].text
	panels[0].get_children()[0].text = panel4_prev_text
	anim.play("RESET")
	EventBus.broadcast("SEQUENCE_DISPLAY_CYCLED", "NULLDATA")
