extends Control
class_name HUD

@onready var char_info: CharInfo = %CharInfo
@onready var game_log: RichTextLabel = %Log
@onready var log_timer: Timer = %LogTimer
@onready var sequence_display: SequenceDisplay = %SequenceDisplay
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var settings_menu: SettingsMenu = %SettingsMenu

func _ready()->void:
	EventBus.subscribe("PRINT_LOG", self, "print_log")
	EventBus.subscribe("SELECTION_CHANGED", self, "set_char_info")
	log_timer.timeout.connect(game_log.get_parent().hide)

func submenu_opened()->void:
	char_info.hide()
	game_log.get_parent().hide()
	sequence_display.hide()

func submenu_closed()->void:
	if char_info.character != null:
		char_info.show()
	if log_timer.time_left > 0:
		game_log.get_parent().show()
	sequence_display.show()

func set_char_info(selected: Node2D)->void:
	if selected is not Character && selected is not Ability || selected == null:
		char_info.set_character(null)
		char_info.close_menu()
	elif selected is Character:
		char_info.set_character(selected)
	else:
		char_info.set_character(selected.user)

func print_log(data)->void:
	game_log.get_parent().show()
	game_log.text += str(data)+"\n"
	log_timer.start()
