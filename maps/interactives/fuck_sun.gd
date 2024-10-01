extends Interactive

@onready var audio: AudioStreamPlayer2D = %AudioStreamPlayer2D

func _interacted(_character: Character):
	audio.play()
