extends SettingsMenuChild
class_name ControlsMenu
## Menu containing keybind settings
##
## Currently unused

func _ready() -> void:
	set_values()

func placeholder_button_pressed() -> void:
	Settings.controls.placeholder = "w"

func set_values()->void:
	return
