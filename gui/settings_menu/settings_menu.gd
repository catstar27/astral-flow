extends Control
class_name SettingsMenu
## The settings menu; uses a set of submenus to change game settings
##
## Contains buttons for selecting submenus, saving settings, and resetting them

@onready var tab_menu: TabMenu = %TabMenu ## Tab menu containing the settings menus
var menu_open: bool = false ## Whether this menu is open
signal settings_opened ## Emitted when the menu is opened
signal settings_closed ## Emitted when the menu is closed

## Opens the menu and selects the gameplay submenu
func open_settings_menu()->void:
	menu_open = true
	show()
	EventBus.broadcast("PAUSE", "NULLDATA")
	for menu in tab_menu.get_children():
		if menu is SettingsMenuChild:
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
	for menu in tab_menu.get_children():
		if menu is SettingsMenuChild:
			menu.set_values()
	close_settings_menu()

## Resets the settings to default
func default_settings()->void:
	Settings.reset_default()
	for menu in tab_menu.get_children():
		if menu is SettingsMenuChild:
			menu.set_values()

func _unhandled_input(event: InputEvent) -> void:
	if !menu_open:
		return
	if event.is_action_released("menu_back") || event.is_action_released("menu"):
		get_viewport().set_input_as_handled()
		close_settings_menu()
