extends VBoxContainer
class_name SequenceDisplay

func _ready()->void:
	EventBus.subscribe("ROUND_STARTED", self, "update_display")
	EventBus.subscribe("TURN_ENDED", self, "hide_top")
	EventBus.subscribe("COMBAT_ENDED", self, "hide")

func update_display(order: Array[Character])->void:
	for child in get_children():
		child.queue_free()
	for character in order:
		var panel: PanelContainer = PanelContainer.new()
		panel.use_parent_material = true
		var new_label: Label = Label.new()
		new_label.use_parent_material = true
		new_label.text = character.display_name
		add_child(panel)
		panel.add_child(new_label)
	show()

func hide_top()->void:
	get_child(0).queue_free()
