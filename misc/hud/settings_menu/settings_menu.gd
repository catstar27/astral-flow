extends Control
class_name SettingsMenu

@onready var menus: Array[SettingsMenuChild] = [
	%GameplayMenu,
	%VideoMenu,
	%AudioMenu,
	%ControlsMenu
]
@onready var buttons: Array[Button] = [
	%GameplayCategory,
	%VideoCategory,
	%AudioCategory,
	%ControlsCategory
]
var menu_index: int = -1
var menu_open: bool = false
signal settings_opened
signal settings_closed

func open_settings_menu()->void:
	menu_open = true
	select_gameplay()
	show()
	EventBus.broadcast("PAUSE", "NULLDATA")
	for menu in menus:
		menu.set_values()
	settings_opened.emit()

func close_settings_menu()->void:
	menu_open = false
	hide()
	EventBus.broadcast("UNPAUSE", "NULLDATA")
	settings_closed.emit()
	Settings.save_settings()

func cancel_settings()->void:
	Settings.load_settings()
	for menu in menus:
		menu.set_values()
	close_settings_menu()

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

func select_next()->void:
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = (menu_index+1)%4
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true

func select_prev()->void:
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = (menu_index-1)%4
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true

func select_gameplay()->void:
	if menu_index == 0:
		buttons[menu_index].button_pressed = true
		return
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = 0
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true

func select_video()->void:
	if menu_index == 1:
		buttons[menu_index].button_pressed = true
		return
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = 1
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true

func select_audio()->void:
	if menu_index == 2:
		buttons[menu_index].button_pressed = true
		return
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = 2
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true

func select_controls()->void:
	if menu_index == 3:
		buttons[menu_index].button_pressed = true
		return
	buttons[menu_index].button_pressed = false
	menus[menu_index].deselect()
	menu_index = 3
	menus[menu_index].select()
	buttons[menu_index].button_pressed = true
