extends Node2D
class_name SoundManager

@onready var ost: AudioStreamPlayer = %OST
var master_volume: float = .5
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var dialogue_volume: float = 1.0

func _ready() -> void:
	ost.bus = "Music"
	Dialogic.Audio.base_music_player.bus = "Music"
	Dialogic.Audio.base_sound_player.bus = "Dialogue"
	change_volume()
	EventBus.subscribe("PLAY_SOUND", self, "new_sound")
	EventBus.subscribe("SET_OST", self, "new_ost")
	EventBus.subscribe("ENTER_DIALOGUE", self, "enter_dialogue")
	EventBus.subscribe("FADE_MUSIC", self, "fade_music")
	EventBus.subscribe("AUDIO_SETTINGS_CHANGED", self, "change_volume")
	Dialogic.timeline_ended.connect(exit_dialogue)

func change_volume()->void:
	master_volume = Settings.audio.master_volume
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	music_volume = Settings.audio.music_volume
	AudioServer.set_bus_volume_db(1, linear_to_db(music_volume))
	sfx_volume = Settings.audio.sfx_volume
	AudioServer.set_bus_volume_db(2, linear_to_db(sfx_volume))
	dialogue_volume = Settings.audio.dialogue_volume
	AudioServer.set_bus_volume_db(3, linear_to_db(dialogue_volume))

func new_sound(info: Array)->void:
	if info[0] is not AudioStreamWAV:
		print(info[0])
		printerr("Invalid Audio File Path")
	elif info[1] == "positional":
		if info[2] is Vector2:
			var audio_node: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
			audio_node.position = info[2]
			audio_node.bus = "SFX"
			audio_node.stream = info[0]
			audio_node.finished.connect(audio_node.queue_free)
			audio_node.autoplay = true
			add_child(audio_node)
		else:
			printerr("Invalid Position for Positional Audio")
	elif info[1] == "global":
		var audio_node: AudioStreamPlayer = AudioStreamPlayer.new()
		audio_node.bus = "SFX"
		audio_node.stream = info[0]
		audio_node.finished.connect(audio_node.queue_free)
		audio_node.autoplay = true
		add_child(audio_node)
	else:
		printerr("Unrecognized Audio Position")

func new_ost(song: String)->void:
	ost.stream = load(song)
	ost.play()

func fade_music(time: float)->void:
	await create_tween().tween_property(ost, "volume_db", -10, time).finished
	ost.stream_paused = true

func enter_dialogue(info: Array)->void:
	if info[1]:
		fade_music(.5)
	else:
		create_tween().tween_property(ost, "volume_db", linear_to_db(music_volume/4), .5)

func exit_dialogue()->void:
	if ost.stream_paused:
		ost.stream_paused = false
	create_tween().tween_property(ost, "volume_db", linear_to_db(music_volume), .5)
