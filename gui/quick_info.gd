extends PanelContainer
class_name QuickInfo
## Displays a small set of useful information about a character
## 
## Meant to be shown when the character is hovered over

@export var generic_portrait: Texture2D ## Generic character portrait for backup
@onready var name_label: RichTextLabel = %NameLabel ## Label for character's name
@onready var stats_label: RichTextLabel = %StatsLabel ## Label for character's stats
@onready var portrait: TextureRect = %Portrait ## Character Portrait
@onready var status_grid: GridContainer = %StatusGrid ## Container holding status displays
var character: Character = null ## Character this is tracking

func _ready() -> void:
	EventBus.subscribe("SHOW_QUICK_INFO", self, "track_character")
	EventBus.subscribe("HIDE_QUICK_INFO", self, "stop_tracking")

## Starts tracking the given character
func track_character(to_track: Character)->void:
	character = to_track
	update_info()
	update_statuses()
	character.stats_changed.connect(update_info)
	character.status_manager.status_list_changed.connect(update_statuses)
	character.status_manager.status_ticked.connect(update_statuses)
	show()

## Stops tracking the current character
func stop_tracking()->void:
	hide()
	if character == null:
		return
	character.stats_changed.disconnect(update_info)
	character.status_manager.status_list_changed.disconnect(update_statuses)
	character.status_manager.status_ticked.disconnect(update_statuses)
	character = null

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

func update_statuses()->void:
	if character == null:
		return
	var status_list: Dictionary[Status, int] = character.status_manager.status_list.duplicate()
	for status in status_list.keys():
		print(str(status)+":"+str(status_list[status]))
