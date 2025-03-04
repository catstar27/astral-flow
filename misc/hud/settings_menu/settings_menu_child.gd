extends PanelContainer
class_name SettingsMenuChild
## Menu in the settings menu that can hold various settings
##
## This is a base class and is not used directly

@export var first_selection: Control = null ## Button to focus first

## Selects this menu, showing it and grabbing focus on the first setting
func select()->void:
	show()
	if first_selection != null:
		first_selection.grab_focus()

## Hides this menu
func deselect()->void:
	hide()

## Sets the values in this menu to match the current settings
func set_values()->void:
	return
