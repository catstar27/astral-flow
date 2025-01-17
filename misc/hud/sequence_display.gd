extends Control
class_name SequenceDisplay

@onready var anim: AnimationPlayer = %AnimationPlayer
@onready var panels: Array[PanelContainer] = [
	%PanelContainer,
	%PanelContainer2,
	%PanelContainer3,
	%PanelContainer4
]
var current_index: int = 0
var current_order: Array[Character] = []

func _ready()->void:
	EventBus.subscribe("ROUND_STARTED", self, "update_display")
	EventBus.subscribe("TURN_ENDED", self, "cycle_display")
	EventBus.subscribe("COMBAT_ENDED", self, "hide")

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

func cycle_display()->void:
	current_index += 1
	anim.play("cycle")

func end_cycle()->void:
	var panel4_prev_text: String = panels[3].get_children()[0].text
	panels[3].get_children()[0].text = panels[2].get_children()[0].text
	panels[2].get_children()[0].text = panels[1].get_children()[0].text
	panels[1].get_children()[0].text = panels[0].get_children()[0].text
	panels[0].get_children()[0].text = panel4_prev_text
	anim.play("RESET")
	EventBus.broadcast("SEQUENCE_DISPLAY_CYCLED", "NULLDATA")
