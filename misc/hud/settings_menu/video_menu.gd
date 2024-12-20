extends SettingsMenuChild
class_name VideoMenu

@onready var fullscreen: CheckButton = %FullscreenButton

func _ready() -> void:
	set_values()

func fullscreen_button_toggled(toggled_on: bool) -> void:
	Settings.change_video("fullscreen", toggled_on)

func set_values()->void:
	fullscreen.button_pressed = Settings.video.fullscreen
