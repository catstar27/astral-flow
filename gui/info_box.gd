extends PanelContainer
class_name InfoBox
## Box for tooltip display

@onready var label: RichTextLabel = %Label ## Text for the tooltip

## Sets the text for this info box
func set_text(text: String)->void:
	label.text = text
	label.reset_size()
	reset_size()
