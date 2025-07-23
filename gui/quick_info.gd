extends PanelContainer
class_name QuickInfo
## Displays a small set of useful information about a character
## 
## Meant to be shown when the character is hovered over

@export var manage_position: bool = true ## Whether this QuickInfo should manage its position or not
@export var animated: bool = true ## Whether this QuickInfo should play the pop in animation
@export var generic_portrait: Texture2D ## Generic character portrait for backup
@export var hide_in_dialogue: bool = true ## Whether this should hide in dialogue
@onready var name_label: RichTextLabel = %NameLabel ## Label for character's name
@onready var stats_label: RichTextLabel = %StatsLabel ## Label for character's stats
@onready var portrait: TextureRect = %Portrait ## Character Portrait
@onready var status_container: VBoxContainer = %StatusContainer ## Container for the status section
@onready var status_display_container: HBoxContainer = %StatusDisplayContainer ## Container holding status displays
var status_display_scn: PackedScene = preload("uid://dymaugwj65l1f") ## Scene for status displays
var character: Character = null ## Character this is tracking
var is_initiating_tracking: bool = false ## Whether this is initiating tracking
signal tracking_initiated ## Emitted when done initiating tracking
signal updated ## Emitted when the display changes

func _ready() -> void:
	EventBus.subscribe("SHOW_QUICK_INFO", self, "track_character")
	EventBus.subscribe("HIDE_QUICK_INFO", self, "stop_tracking")
	EventBus.subscribe("DIALOGUE_ENTERED", self, "check_and_hide")
	EventBus.subscribe("DIALOGUE_EXITED", self, "check_and_show")

## Checks if this tracking, and shows it if so
func check_and_show()->void:
	if character != null:
		show()

## Checks if this should hide, and hides if yes
func check_and_hide()->void:
	if hide_in_dialogue:
		hide()

## Starts tracking the given character
func track_character(to_track: Character)->void:
	if character == to_track:
		return
	while is_initiating_tracking:
		await tracking_initiated
	if character == to_track:
		return
	is_initiating_tracking = true
	stop_tracking(true)
	if animated:
		scale = Vector2.ONE*.01
	character = to_track
	update_info()
	update_statuses()
	character.stats_changed.connect(update_info)
	character.status_manager.status_list_changed.connect(update_statuses)
	character.status_manager.status_ticked.connect(update_statuses)
	show()
	if animated:
		await create_tween().tween_property(self, "scale", Vector2.ONE, .1).finished
	is_initiating_tracking = false
	tracking_initiated.emit()

## Stops tracking the current character
func stop_tracking(ignore_starting: bool = false)->void:
	if character == null:
		return
	while is_initiating_tracking && !ignore_starting:
		await tracking_initiated
	if character == null:
		return
	is_initiating_tracking = true
	if animated:
		await create_tween().tween_property(self, "scale", Vector2.ONE*.01, .1).finished
	hide()
	character.stats_changed.disconnect(update_info)
	character.status_manager.status_list_changed.disconnect(update_statuses)
	character.status_manager.status_ticked.disconnect(update_statuses)
	character = null
	if !ignore_starting:
		is_initiating_tracking = false
		tracking_initiated.emit()

## Updates the info based on the tracked character
func update_info()->void:
	if character == null:
		return
	if character.portrait != null:
		portrait.texture = character.portrait
	else:
		portrait.texture = generic_portrait
	name_label.text = character.display_name
	stats_label.text = "HP: "+str(character.cur_hp)+"\n"
	stats_label.text += "AP: "+str(character.cur_ap)+"\n"
	stats_label.text += "MP: "+str(character.cur_mp)
	updated.emit()

## Updates the displayed status effects
func update_statuses()->void:
	if character == null:
		return
	if character.status_manager.status_list.keys().size() == 0:
		status_container.hide()
		reset_size()
		if manage_position:
			position.x = get_parent().size.x/2 - size.x/2
		return
	status_container.show()
	var status_list: Dictionary[Status, Array] = character.status_manager.status_list.duplicate()
	var status_arr: Array = status_list.keys()
	var status_displays: Array = status_display_container.get_children()
	var index: int = 0
	for status in status_arr:
		if index >= status_displays.size():
			var new_display: StatusDisplay = status_display_scn.instantiate()
			status_display_container.add_child(new_display)
			status_displays.append(new_display)
		status_displays[index].display_status(status_arr[index],status_list[status][1],status_list[status][0])
		index += 1
	while index < status_displays.size():
		status_displays[index].hide()
		index += 1
	reset_size()
	if manage_position:
		position.x = get_parent().size.x/2 - size.x/2
	updated.emit()
