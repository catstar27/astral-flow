extends Control
class_name HUD

@onready var char_info: CharInfo = %CharInfo
@onready var game_log: RichTextLabel = %Log
@onready var log_timer: Timer = %LogTimer
@onready var sequence_display: SequenceDisplay = %SequenceDisplay
@onready var pause_menu: PauseMenu = %PauseMenu

func _ready()->void:
	EventBus.subscribe("PRINT_LOG", self, "print_log")
	EventBus.subscribe("SELECTION_CHANGED", self, "set_char_info")
	char_info.hide()
	log_timer.timeout.connect(game_log.get_parent().hide)

func set_char_info(selected: Node2D)->void:
	if selected is not Character && selected is not Ability || selected == null:
		char_info.hide()
	elif selected is Character:
		char_info.set_character(selected)
		char_info.show()
	else:
		char_info.set_character(selected.user)
		char_info.show()

func print_log(data)->void:
	game_log.get_parent().show()
	game_log.text += str(data)+"\n"
	log_timer.start()
