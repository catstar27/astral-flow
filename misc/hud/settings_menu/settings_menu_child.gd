extends PanelContainer
class_name SettingsMenuChild

@export var first_selection: Control = null

func select()->void:
	show()
	if first_selection != null:
		first_selection.grab_focus()

func deselect()->void:
	hide()
