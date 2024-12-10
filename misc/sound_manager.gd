extends Node2D
class_name SoundManager

@onready var ost: AudioStreamPlayer = %OST
var ost_volume: float = 0.75

func _ready() -> void:
	ost.volume_db = linear_to_db(ost_volume)
	EventBus.subscribe("PLAY_SOUND", self, "new_sound")
	EventBus.subscribe("SET_OST", self, "new_ost")
	EventBus.subscribe("ENTER_DIALOGUE", self, "enter_dialogue")
	Dialogic.timeline_ended.connect(exit_dialogue)

func new_sound(info: Array)->void:
	if info[0] is not String:
		printerr("Invalid Audio File Path")
	elif info[1] == "positional":
		if info[2] is Vector2:
			var audio_node: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
			audio_node.position = info[2]
			audio_node.stream = load(info[0])
			audio_node.finished.connect(audio_node.queue_free)
			audio_node.autoplay = true
			add_child(audio_node)
		else:
			printerr("Invalid Position for Positional Audio")
	elif info[1] == "global":
		var audio_node: AudioStreamPlayer = AudioStreamPlayer.new()
		audio_node.stream = load(info[0])
		audio_node.finished.connect(audio_node.queue_free)
		audio_node.autoplay = true
		add_child(audio_node)
	else:
		printerr("Unrecognized Audio Position")

func new_ost(song: String)->void:
	ost.stream = load(song)
	ost.play()

func enter_dialogue(info: Array)->void:
	if info[1]:
		await create_tween().tween_property(ost, "volume_db", -10, .5).finished
		ost.stream_paused = true
	else:
		create_tween().tween_property(ost, "volume_db", linear_to_db(ost_volume/4), .5)

func exit_dialogue()->void:
	if ost.stream_paused:
		ost.stream_paused = false
	create_tween().tween_property(ost, "volume_db", linear_to_db(ost_volume), .5)
