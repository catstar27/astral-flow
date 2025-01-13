extends Control
class_name HUD

@onready var char_info: CharInfo = %CharInfo
@onready var utility_menu: UtilityMenu = %UtilityMenu
@onready var game_log: RichTextLabel = %Log
@onready var log_timer: Timer = %LogTimer
@onready var sequence_display: SequenceDisplay = %SequenceDisplay
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var settings_menu: SettingsMenu = %SettingsMenu
@onready var time_label: Label = %TimeLabel
var sequence_display_visible: bool = false

func _ready()->void:
	EventBus.subscribe("PRINT_LOG", self, "print_log")
	EventBus.subscribe("SELECTION_CHANGED", self, "set_char_info")
	EventBus.subscribe("TIME_CHANGED", self, "set_time_label")
	log_timer.timeout.connect(game_log.get_parent().hide)

func submenu_opened()->void:
	char_info.hide()
	utility_menu.hide()
	game_log.get_parent().hide()
	sequence_display_visible = sequence_display.visible
	sequence_display.hide()

func submenu_closed()->void:
	char_info.show()
	utility_menu.show()
	if log_timer.time_left > 0:
		game_log.get_parent().show()
	if sequence_display_visible:
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

func set_time_label(time: Array)->void:
	if time[0] is not int || time[1] is not int:
		printerr("Attempted to Update Time Display with Invalid Time")
		return
	time_label.text = ''
	if time[1] < 10:
		time_label.text += '0'
	time_label.text += str(time[1])+':'
	if time[0] < 10:
		time_label.text += '0'
	time_label.text += str(time[0])
