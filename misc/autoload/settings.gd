extends Node

var settings_file_location: String = "user://settings.cfg"
var settings_file: ConfigFile = ConfigFile.new()
var gameplay: Dictionary = {
	"selection_tint": Color.DEEP_SKY_BLUE,
	"attack_indicator_tint": Color.DARK_ORANGE,
	"support_indicator_tint": Color.DARK_GREEN,
}
var video: Dictionary = {
	"fullscreen": false,
}
var audio: Dictionary = {
	"master_volume": .5,
	"music_volume": 1.0,
	"sfx_volume": 1.0,
	"dialogue_volume": 1.0
}
var controls: Dictionary = {
	"placeholder": "s"
}

func _ready() -> void:
	settings_file.load(settings_file_location)
	if !FileAccess.file_exists(settings_file_location):
		save_settings()
	else:
		load_settings()

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

func change_gameplay(setting: String, value)->void:
	gameplay[setting] = value
	EventBus.broadcast(EventBus.Event.new("GAMEPLAY_SETTINGS_CHANGED", "NULLDATA"))

func change_video(setting: String, value)->void:
	video[setting] = value
	EventBus.broadcast(EventBus.Event.new("VIDEO_SETTINGS_CHANGED", "NULLDATA"))

func change_audio(setting: String, value)->void:
	audio[setting] = value
	EventBus.broadcast(EventBus.Event.new("AUDIO_SETTINGS_CHANGED", "NULLDATA"))

func change_controls(setting: String, value)->void:
	controls[setting] = value
	EventBus.broadcast(EventBus.Event.new("CONTROLS_SETTINGS_CHANGED", "NULLDATA"))

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
	EventBus.broadcast(EventBus.Event.new("GAMEPLAY_SETTINGS_CHANGED", "NULLDATA"))
	EventBus.broadcast(EventBus.Event.new("VIDEO_SETTINGS_CHANGED", "NULLDATA"))
	EventBus.broadcast(EventBus.Event.new("AUDIO_SETTINGS_CHANGED", "NULLDATA"))
	EventBus.broadcast(EventBus.Event.new("CONTROLS_SETTINGS_CHANGED", "NULLDATA"))

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
