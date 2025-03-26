extends SettingsMenuChild
class_name VideoMenu
## Menu containing video settings

@onready var fullscreen: CheckButton = %FullscreenButton ## Whether the game is fullscreen

func _ready() -> void:
	set_values()

func fullscreen_button_toggled(toggled_on: bool) -> void:
	Settings.change_video("fullscreen", toggled_on)

func set_values()->void:
	fullscreen.button_pressed = Settings.video.fullscreen
