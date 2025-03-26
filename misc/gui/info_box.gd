extends PanelContainer
class_name InfoBox

@onready var label: RichTextLabel = %Label

## Sets the text for this info box
func set_text(text: String)->void:
	label.text = text
	label.reset_size()
	reset_size()
