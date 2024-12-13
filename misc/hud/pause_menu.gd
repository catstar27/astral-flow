extends Control
class_name PauseMenu

@onready var resume_button: Button = %Resume
@onready var save_button: Button = %Save
@onready var load_button: Button = %Load
@onready var settings_button: Button = %Settings
@onready var quit_button: Button = %Quit
var menu_open: bool = false

func _ready() -> void:
	EventBus.subscribe("START_COMBAT", self, "started_combat")
	EventBus.subscribe("COMBAT_ENDED", self, "ended_combat")

func started_combat(_data: Array[Character])->void:
	save_button.disabled = true

func ended_combat()->void:
	save_button.disabled = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("menu"):
		if !menu_open and !get_tree().paused:
			open_pause_menu()
		elif menu_open:
			close_pause_menu()

func open_pause_menu()->void:
	resume_button.grab_focus()
	menu_open = true
	EventBus.broadcast(EventBus.Event.new("PAUSE", "NULLDATA"))
	show()

func close_pause_menu()->void:
	menu_open = false
	EventBus.broadcast(EventBus.Event.new("UNPAUSE", "NULLDATA"))
	hide()

func save_pressed()->void:
	pass

func load_pressed()->void:
	pass

func settings_pressed()->void:
	pass

func quit_pressed()->void:
	get_tree().quit()
