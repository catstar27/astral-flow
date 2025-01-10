extends Control
class_name SequenceDisplay

func _ready()->void:
	EventBus.subscribe("ROUND_STARTED", self, "update_display")
	EventBus.subscribe("TURN_ENDED", self, "hide_top")
	EventBus.subscribe("COMBAT_ENDED", self, "hide")

func update_display(_order: Array[Character])->void:
	show()
