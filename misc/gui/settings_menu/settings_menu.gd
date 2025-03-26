extends Control
class_name SettingsMenu
## The settings menu; uses a set of submenus to change game settings
##
## Contains buttons for selecting submenus, saving settings, and resetting them

@onready var menus: Array[SettingsMenuChild] = [ ## The settings submenus
	%GameplayMenu, ## Controls gameplay settings
	%VideoMenu, ## Controls video settings
	%AudioMenu, ## Controls audio settings
	%ControlsMenu ## Controls controls settings
]
@onready var buttons: Array[Button] = [ ## Buttons corresponding to the submenus
	%GameplayCategory, ## Corresponds to gameplay settings
	%VideoCategory, ## Corresponds to video settings
	%AudioCategory, ## Corresponds to audio settings
	%ControlsCategory ## Corresponds to controls settings
]
var menu_index: int = -1 ## Index of currently selected menu
var menu_open: bool = false ## Whether this menu is open
signal settings_opened ## Emitted when the menu is opened
signal settings_closed ## Emitted when the menu is closed

## Opens the menu and selects the gameplay submenu
func open_settings_menu()->void:
	menu_open = true
	select_gameplay()
	show()
	EventBus.broadcast("PAUSE", "NULLDATA")
	for menu in menus:
		menu.set_values()
	settings_opened.emit()

## Closes the menu and saves
func close_settings_menu()->void:
	menu_open = false
	hide()
	EventBus.broadcast("UNPAUSE", "NULLDATA")
	settings_closed.emit()
	Settings.save_settings()

## Closes the menu without saving
func cancel_settings()->void:
	Settings.load_settings()
	for menu in menus:
		menu.set_values()
	close_settings_menu()

## Resets the settings to default
func default_settings()->void:
	Settings.reset_default()
	for menu in menus:
		menu.set_values()

func _unhandled_input(event: InputEvent) -> void:
	if !menu_open:
		return
	if event.is_action_released("menu_back") || event.is_action_released("menu"):
		get_viewport().set_input_as_handled()
		close_settings_menu()

## Selects the next (right) settings menu
func select_next()->void:
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = (menu_index+1)%4
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true

## Selects the previous (left) settings menu
func select_prev()->void:
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = (menu_index-1)%4
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true

## Selects the gameplay menu regardless of current menu
func select_gameplay()->void:
	if menu_index == 0:
		buttons[menu_index].button_pressed = true
		return
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = 0
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true

## Selects the video menu regardless of current menu
func select_video()->void:
	if menu_index == 1:
		buttons[menu_index].button_pressed = true
		return
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = 1
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true

## Selects the audio menu regardless of current menu
func select_audio()->void:
	if menu_index == 2:
		buttons[menu_index].button_pressed = true
		return
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = 2
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true

## Selects the controls menu regardless of current menu
func select_controls()->void:
	if menu_index == 3:
		buttons[menu_index].button_pressed = true
		return
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = 3
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true
