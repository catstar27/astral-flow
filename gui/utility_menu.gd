extends Control
class_name UtilityMenu
## Menu holding utility buttons, such as the party menu and the map

@onready var info_container: VBoxContainer = %Info ## Container holding the utility buttons
@onready var menu_button: ControlDisplayButton = %MenuButton ## Button that toggles the menu
@onready var top_button: Button = %Party ## Menu's top button
enum states{ ## States the menu can be in
	closed, ## The menu is closed
	open, ## The menu is open
	suspended ## The menu is suspended (unused)
}
var state: states = states.closed ## Current menu state
var changing_state: bool = false ## Whether the menu is changing state
signal opened ## Emitted when this menu opens
signal closed ## Emitted when this menu closes
signal journal_button_pressed ## Emitted when the journal button is pressed
signal map_button_pressed ## Emitted when the map button is pressed
signal inventory_button_pressed ## Emitted when the inventory button is pressed
signal pause_button_pressed ## Emitted when the pause button is pressed
signal character_sheet_requested(character: Character) ## Emitted to open a character sheet

func _ready() -> void:
	menu_button.display_updated.connect(update_menu_button)

## Updates the menu button's position
func update_menu_button()->void:
	menu_button.position.x = -menu_button.size.x

## Toggles the menu state between open and closed
func toggle_menu()->void:
	if state != states.closed:
		close_menu()
	else:
		open_menu()

## Finds the position of the menu when open
func get_open_position()->Vector2:
	var largest_width: float = 0
	if menu_button.size.x > info_container.size.x:
		largest_width = menu_button.size.x
	else:
		largest_width = info_container.size.x
	return Vector2(-largest_width-2, info_container.position.y)

## Opens the menu
func open_menu()->void:
	if state != states.closed || changing_state:
		return
	changing_state = true
	state = states.open
	menu_button.text = "→"
	modulate = Color(1,1,1,1)
	info_container.show()
	for button in info_container.get_children():
		button.set_disabled(false)
	opened.emit()
	await create_tween().tween_property(info_container, "position", get_open_position(), .5).finished
	EventBus.broadcast("DEACTIVATE_SELECTION", "NULLDATA")
	top_button.grab_focus()
	changing_state = false

## Closes the menu
func close_menu()->void:
	if state == states.closed || changing_state:
		return
	changing_state = true
	var activate_selection: bool = true
	if state == states.suspended:
		activate_selection = false
	state = states.closed
	for button in info_container.get_children():
		button.set_disabled(true)
	closed.emit()
	menu_button.text = "←"
	if activate_selection:
		EventBus.broadcast("ACTIVATE_SELECTION", "NULLDATA")
	await create_tween().tween_property(info_container, "position", Vector2(0, info_container.position.y), .5).finished
	modulate = Color(1,1,1,1)
	info_container.hide()
	changing_state = false

## Emits the signal for the journal button
func journal_pressed()->void:
	journal_button_pressed.emit()

## Emits the signal for the map button
func map_pressed()->void:
	map_button_pressed.emit()

## Emits the signal for the inventory button
func inventory_pressed()->void:
	inventory_button_pressed.emit()

## Emits the signal for the pause button
func pause_pressed()->void:
	pause_button_pressed.emit()

## Grabs focus on the party button
func focus_party()->void:
	%Party.grab_focus()

## Grabs focus on the journal button
func focus_journal()->void:
	%Journal.grab_focus()

## Grabs focus on the map button
func focus_map()->void:
	%Map.grab_focus()

## Grabs focus on the inventory button
func focus_inventory()->void:
	%Inventory.grab_focus()

## Grabs focus on the pause button
func focus_pause()->void:
	%Pause.grab_focus()

## Hides the menu buttons while keeping the menu open
func hide_buttons()->void:
	info_container.hide()

## Shows the menu buttons
func show_buttons()->void:
	info_container.show()

func request_open_character_sheet(character: Character) -> void:
	character_sheet_requested.emit(character)
