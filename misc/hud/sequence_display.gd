extends VBoxContainer
class_name SequenceDisplay

func update_display(order: Array[Character])->void:
	for child in get_children():
		child.queue_free()
	for character in order:
		var panel: PanelContainer = PanelContainer.new()
		var new_label: Label = Label.new()
		new_label.text = character.display_name
		add_child(panel)
		panel.add_child(new_label)
	show()

func hide_top()->void:
	get_child(0).queue_free()
