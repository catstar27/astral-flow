extends Control
class_name GUI
## The primary GUI node; all elements of the GUI are children of this

@onready var char_info: CharInfo = %CharInfo ## CharInfo node
@onready var utility_menu: UtilityMenu = %UtilityMenu ## UtilityMenu node
@onready var game_log: RichTextLabel = %Log ## The game's log
@onready var log_timer: Timer = %LogTimer ## Timer that hides the log when inactive
@onready var sequence_display: SequenceDisplay = %SequenceDisplay ## SequenceDisplay node
@onready var quest_tracker: QuestTracker = %QuestTracker ## QuestTracker node
@onready var pause_menu: PauseMenu = %PauseMenu ## PauseMenu node
@onready var settings_menu: SettingsMenu = %SettingsMenu ## SettingsMenu node
@onready var time_label: Label = %TimeLabel ## Label showing game time
@onready var info_box: InfoBox = %InfoBox ## Box containing context-sensitive info
var sequence_display_visible: bool = false ## Whether the sequence display is visible
var info_box_requester: Control ## Node that is currently displaying the info box
signal cutscene_started ## Emitted when a cutscene starts
signal cutscene_ended ## Emitted when a cutscene ends

func _ready()->void:
	EventBus.subscribe("ENTER_DIALOGUE", self, "enter_dialogue")
	EventBus.subscribe("PRINT_LOG", self, "print_log")
	EventBus.subscribe("SELECTION_CHANGED", self, "set_char_info")
	EventBus.subscribe("TIME_CHANGED", self, "set_time_label")
	EventBus.subscribe("CUTSCENE_STARTED", self, "start_cutscene")
	EventBus.subscribe("CUTSCENE_ENDED", self, "end_cutscene")
	log_timer.timeout.connect(game_log.get_parent().hide)
	for child in get_children():
		if child.has_signal("info_box_requested"):
			child.info_box_requested.connect(change_info_box)

## Called to move the info box and change its text
func change_info_box(requester: Control, origin: Vector2, text: String)->void:
	if info_box_requester != null:
		info_box_requester.info_box_closed.disconnect(info_box.hide)
	info_box.show()
	info_box_requester = requester
	requester.info_box_closed.connect(info_box.hide)
	info_box.position = origin
	info_box.set_text(text)

## Sets the character tracked by CharInfo display
func set_char_info(selected: Node2D)->void:
	if selected is not Character || selected == null:
		char_info.set_character(null)
		char_info.close_menu()
	elif selected is Character:
		char_info.set_character(selected)
	else:
		char_info.set_character(selected.user)

## Prints the given data to the log
func print_log(data)->void:
	game_log.get_parent().show()
	game_log.text += str(data)+"\n"
	log_timer.start()

## Updates the label showing current game time
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

## Hides certain elements when dialogue starts
func enter_dialogue(_info: Array)->void:
	game_log.get_parent().hide()

## Disables gui elements that should not function in a cutscene
func start_cutscene()->void:
	cutscene_started.emit()

## Enables disabled gui elements that should not function in a cutscene
func end_cutscene()->void:
	cutscene_ended.emit()
