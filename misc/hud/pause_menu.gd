extends Control
class_name PauseMenu

@onready var resume_button: Button = %Resume
@onready var save_button: Button = %Save
@onready var load_button: Button = %Load
@onready var settings_button: Button = %Settings
@onready var quit_button: Button = %Quit
var menu_open: bool = false
signal open_settings
signal pause_opened
signal pause_closed

func _ready() -> void:
	EventBus.subscribe("START_COMBAT", self, "started_combat")
	EventBus.subscribe("COMBAT_ENDED", self, "ended_combat")

func started_combat(_data: Array[Character])->void:
	save_button.disabled = true

func ended_combat()->void:
	save_button.disabled = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("menu"):
		get_viewport().set_input_as_handled()
		if !menu_open and !get_tree().paused:
			open_pause_menu()
		elif menu_open:
			close_pause_menu()

func open_pause_menu()->void:
	resume_button.grab_focus()
	menu_open = true
	EventBus.broadcast("PAUSE", "NULLDATA")
	show()
	pause_opened.emit()

func close_pause_menu()->void:
	menu_open = false
	EventBus.broadcast("UNPAUSE", "NULLDATA")
	hide()
	pause_closed.emit()

func save_pressed()->void:
	SaveLoad.save_data()

func load_pressed()->void:
	close_pause_menu()
	SaveLoad.load_data()

func settings_pressed()->void:
	close_pause_menu()
	open_settings.emit()

func quit_pressed()->void:
	get_tree().quit()

func reset_pressed() -> void:
	SaveLoad.reset_save("save1")
