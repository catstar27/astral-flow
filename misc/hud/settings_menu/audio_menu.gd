extends SettingsMenuChild
class_name AudioMenu

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var dialogue_slider: HSlider = %DialogueSlider

func _ready() -> void:
	set_values()

func master_slider_value_changed(value: float) -> void:
	Settings.change_audio("master_volume", value)

func music_slider_value_changed(value: float) -> void:
	Settings.change_audio("music_volume", value)

func sfx_slider_value_changed(value: float) -> void:
	Settings.change_audio("sfx_volume", value)

func voice_slider_value_changed(value: float) -> void:
	Settings.change_audio("dialogue_volume", value)

func set_values()->void:
	master_slider.value = Settings.audio.master_volume
	music_slider.value = Settings.audio.music_volume
	sfx_slider.value = Settings.audio.sfx_volume
	dialogue_slider.value = Settings.audio.dialogue_volume
