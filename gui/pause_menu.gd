extends Control
class_name PauseMenu
## Pause menu containing various buttons

@onready var resume_button: Button = %Resume ## Unpauses and closes the pause menu
@onready var save_button: Button = %Save ## Saves the game
var menu_open: bool = false ## Whether the menu is open
signal open_settings ## Emitted when settings is opened
signal pause_opened ## Emitted when the pause menu is opened
signal pause_closed ## Emitted when the pause menu is closed

func _ready() -> void:
	EventBus.subscribe("START_COMBAT", self, "started_combat")
	EventBus.subscribe("COMBAT_ENDED", self, "ended_combat")

## Disables save button when combat starts
func started_combat(_data: Array[Character])->void:
	save_button.disabled = true

## Allows saving when combat is over
func ended_combat()->void:
	save_button.disabled = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		if !menu_open and !get_tree().paused:
			open_pause_menu()
		elif menu_open:
			close_pause_menu()

## Opens the menu and pauses
func open_pause_menu()->void:
	resume_button.grab_focus()
	menu_open = true
	EventBus.broadcast("PAUSE", "NULLDATA")
	show()
	pause_opened.emit()

## Closes the menu and unpauses; called when resume is pressed
func close_pause_menu()->void:
	menu_open = false
	EventBus.broadcast("UNPAUSE", "NULLDATA")
	hide()
	pause_closed.emit()

## Saves the game; called when the save button is pressed
func save_pressed()->void:
	close_pause_menu()
	SaveLoad.save_data()
	open_pause_menu()
	save_button.grab_focus()

## Reloads the save; called when the load button is pressed
func load_pressed()->void:
	close_pause_menu()
	SaveLoad.load_data()

## Opens the settings; called when settings button is pressed
func settings_pressed()->void:
	close_pause_menu()
	open_settings.emit()

## Closes the game; called when quit button is pressed
func quit_pressed()->void:
	get_tree().quit()

## Resets the save file; called when reset button is pressed
func reset_pressed() -> void:
	SaveLoad.reset_save(SaveLoad.slot)
