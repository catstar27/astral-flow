extends Node
## Autoload that tracks and saves all the game's settings
##
## Settings are stored separately from actual save files,
## allowing them to be constant between saves.

var settings_file_location: String = "user://settings.cfg" ## Filepath of the settings file
var settings_file: ConfigFile = ConfigFile.new() ## ConfigFile that stores the saved settings
var gameplay: Dictionary[String, Variant] = { ## Settings related to gameplay, such as indicator colors
	"selection_tint": Color.DEEP_SKY_BLUE, ## Tint for selected characters
	"attack_indicator_tint": Color.DARK_ORANGE, ## Tint for abilities that are hostile
	"support_indicator_tint": Color.DARK_GREEN, ## Tint for abilities that apply support effects
}
var video: Dictionary[String, Variant] = { ## Settings relating to video, such as fullscreen
	"fullscreen": false, ## Whether the game is fullscreen
}
var audio: Dictionary[String, Variant] = { ## Settings relating to audio, such as volumes
	"master_volume": .5, ## Volume of master bus that controls all other volumes
	"music_volume": 1.0, ## Volume of music bus
	"sfx_volume": 1.0, ## Volume of sfx bus
	"dialogue_volume": 1.0 ## Volume of dialogue bus
}
var controls: Dictionary[String, Variant] = { ## Settings related to keybinds
	"placeholder": "s" ## Placeholder for testing; nonfunctional
}

func _ready() -> void:
	settings_file.load(settings_file_location)
	if !FileAccess.file_exists(settings_file_location):
		save_settings()
	else:
		load_settings()

## Resets all settings to their default values
func reset_default()->void:
	gameplay = {
	"selection_tint": Color.DEEP_SKY_BLUE,
	"attack_indicator_tint": Color.DARK_ORANGE,
	"support_indicator_tint": Color.DARK_GREEN,
	}
	video = {
	"fullscreen": false,
	}
	audio = {
	"master_volume": .5,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"dialogue_volume": 1.0
	}
	controls = {
	"placeholder": "s"
	}

## Changes settings in the gameplay dictionary
func change_gameplay(setting: String, value)->void:
	gameplay[setting] = value
	EventBus.broadcast("GAMEPLAY_SETTINGS_CHANGED", "NULLDATA")

## Changes settings in the video dictionary
func change_video(setting: String, value)->void:
	video[setting] = value
	EventBus.broadcast("VIDEO_SETTINGS_CHANGED", "NULLDATA")

## Changes settings in the audio dictionary
func change_audio(setting: String, value)->void:
	audio[setting] = value
	EventBus.broadcast("AUDIO_SETTINGS_CHANGED", "NULLDATA")

## Changes settings in the controls dictionary
func change_controls(setting: String, value)->void:
	controls[setting] = value
	EventBus.broadcast("CONTROLS_SETTINGS_CHANGED", "NULLDATA")

## Loads the settings from the settings file
func load_settings()->void:
	var settings: Array = settings_file.get_section_keys("Gameplay")
	for setting in settings:
		gameplay[setting] = settings_file.get_value("Gameplay", setting)
	settings = settings_file.get_section_keys("Video")
	for setting in settings:
		video[setting] = settings_file.get_value("Video", setting)
	settings = settings_file.get_section_keys("Audio")
	for setting in settings:
		audio[setting] = settings_file.get_value("Audio", setting)
	settings = settings_file.get_section_keys("Controls")
	for setting in settings:
		controls[setting] = settings_file.get_value("Controls", setting)
	EventBus.broadcast("GAMEPLAY_SETTINGS_CHANGED", "NULLDATA")
	EventBus.broadcast("VIDEO_SETTINGS_CHANGED", "NULLDATA")
	EventBus.broadcast("AUDIO_SETTINGS_CHANGED", "NULLDATA")
	EventBus.broadcast("CONTROLS_SETTINGS_CHANGED", "NULLDATA")

## Saves the entire settings file
func save_settings()->void:
	for setting in gameplay:
		settings_file.set_value("Gameplay", setting, gameplay[setting])
	for setting in video:
		settings_file.set_value("Video", setting, video[setting])
	for setting in audio:
		settings_file.set_value("Audio", setting, audio[setting])
	for setting in controls:
		settings_file.set_value("Controls", setting, controls[setting])
	settings_file.save(settings_file_location)
