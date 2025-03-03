extends Control
class_name CharInfo
## GUI Panel that contains information and controls for a selected character
##
## Allows the player to select abilities or end the character's turn

@onready var ability_list: VBoxContainer = %AbilityList ## Container that holds ability buttons
@onready var hp_label: Label = %HP ## Shows the character's health points
@onready var ap_label: Label = %AP ## Shows the character's action points
@onready var mp_label: Label = %MP ## Shows the character's magic points
@onready var end_turn_button: Button = %EndTurn ## Button that ends the character's turn
@onready var info_container: VBoxContainer = %Info ## Container that holds labels for various stats
@onready var menu_button: ControlDisplayButton = %MenuButton ## Button that extends or hides the menu
@export var ability_buttons: Array[AbilityButton] ## Array of all ability buttons
var prev_button_index: int = 0 ## Holds the previously-selected button to reselect it when the menu opens
var character: Character = null ## The character this is tracking
var abilities: Array[Ability] = [] ## Array of the tracked character's abilities
enum states{ ## Contains all the states for the menu
	closed, ## The menu is closed
	open, ## The menu is open and ready for selection
	suspended ## The menu is suspended and transparent
}
var state: states = states.closed ## Current state of the menu
var changing_state: bool = false ## Whether the menu is currently changing states

#region Setup
func _ready() -> void:
	menu_button.disabled = true
	for button in ability_buttons:
		button.pressed.connect(suspend_menu)
#endregion

#region Display States
## Toggles the menu between open and closed
func toggle_menu()->void:
	if state != states.closed:
		close_menu()
	else:
		open_menu()

## Opens the menu
func open_menu()->void:
	if state != states.closed || changing_state:
		return
	changing_state = true
	state = states.open
	menu_button.text = "←"
	modulate = Color(1,1,1,1)
	info_container.show()
	await create_tween().tween_property(info_container, "position", Vector2(0, info_container.position.y), .5).finished
	EventBus.broadcast("DEACTIVATE_SELECTION", "NULLDATA")
	if ability_buttons[prev_button_index].ability != null:
		ability_buttons[prev_button_index].grab_focus()
	changing_state = false

## Closes the menu
func close_menu()->void:
	if state == states.closed || changing_state:
		return
	changing_state = true
	if character != null:
		if character.selected_ability != null:
			character.call_deferred("deselect_ability")
	for button in ability_buttons:
		if button.has_focus():
			prev_button_index = ability_buttons.find(button)
			get_window().gui_release_focus()
		button.disabled = true
	var activate_selection: bool = true
	if state == states.suspended:
		activate_selection = false
	state = states.closed
	menu_button.text = "→"
	if activate_selection:
		EventBus.broadcast("ACTIVATE_SELECTION", "NULLDATA")
	await create_tween().tween_property(info_container, "position", Vector2(-82, info_container.position.y), .5).finished
	modulate = Color(1,1,1,1)
	info_container.hide()
	changing_state = false

## Suspends the menu
func suspend_menu()->void:
	if state == states.suspended || changing_state:
		return
	changing_state = true
	state = states.suspended
	for button in ability_buttons:
		if button.has_focus():
			prev_button_index = ability_buttons.find(button)
			get_window().gui_release_focus()
	await create_tween().tween_property(self, "modulate", Color(1,1,1,.5), .1).finished
	EventBus.broadcast("ACTIVATE_SELECTION", "NULLDATA")
	changing_state = false

## Unsuspends the menu
func unsuspend_menu()->void:
	if state != states.suspended || changing_state:
		return
	changing_state = true
	state = states.open
	await create_tween().tween_property(self, "modulate", Color(1,1,1,1), .1).finished
	EventBus.broadcast("DEACTIVATE_SELECTION", "NULLDATA")
	if ability_buttons[prev_button_index].ability != null:
		ability_buttons[prev_button_index].grab_focus()
	changing_state = false
#endregion

#region Display Updates
## Enables the end turn button, for when combat is entered
func enable_end_turn()->void:
	end_turn_button.disabled = false
	end_turn_button.focus_mode = Control.FOCUS_ALL
	set_first_last_buttons()

## Disables the end turn button, for when it is no longer needed
func disable_end_turn()->void:
	end_turn_button.disabled = true
	end_turn_button.focus_mode = Control.FOCUS_NONE
	set_first_last_buttons()

## Sets neighbors of the first and last buttons, allowing them to wrap around
func set_first_last_buttons()->void:
	if end_turn_button.disabled:
		ability_buttons[0].focus_previous = ability_buttons[abilities.size()-1].get_path()
		ability_buttons[0].focus_neighbor_top = ability_buttons[abilities.size()-1].get_path()
		ability_buttons[abilities.size()-1].focus_next = ability_buttons[0].get_path()
		ability_buttons[abilities.size()-1].focus_neighbor_bottom = ability_buttons[0].get_path()
	else:
		ability_buttons[0].focus_previous = end_turn_button.get_path()
		ability_buttons[0].focus_neighbor_top = end_turn_button.get_path()
		ability_buttons[abilities.size()-1].focus_next = end_turn_button.get_path()
		ability_buttons[abilities.size()-1].focus_neighbor_bottom = end_turn_button.get_path()

## Adds an ability to the button list
func add_ability(index: int, ability: Ability)->AbilityButton:
	var button: AbilityButton = ability_buttons[index]
	var prev: AbilityButton = null
	if index > 0:
		prev = ability_buttons[index-1]
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	button.set_ability(ability)
	if prev != null:
		button.focus_previous = prev.get_path()
		button.focus_neighbor_top = prev.get_path()
		prev.focus_next = button.get_path()
		prev.focus_neighbor_bottom = button.get_path()
	return button

## Sets a new character, updating the display to match
func set_character(new_char: Character)->void:
	if new_char == null:
		if character != null:
			character.stats_changed.disconnect(update_labels)
			end_turn_button.pressed.disconnect(character.end_turn)
			character.abilities_changed.disconnect(update_abilities)
			character.combat_entered.disconnect(enable_end_turn)
			character.combat_exited.disconnect(disable_end_turn)
			character.ability_deselected.disconnect(unsuspend_menu)
			character = null
			menu_button.disabled = true
			create_tween().tween_property(menu_button, "modulate", Color(1,1,1,.5), .1)
		return
	if new_char == character:
		return
	if character != null:
		end_turn_button.pressed.disconnect(character.end_self_turn)
	prev_button_index = 0
	menu_button.disabled = false
	create_tween().tween_property(menu_button, "modulate", Color(1,1,1,1), .1)
	disable_end_turn()
	character = new_char
	abilities = []
	character.stats_changed.connect(update_labels)
	update_labels()
	end_turn_button.pressed.connect(character.end_turn)
	character.abilities_changed.connect(update_abilities)
	character.combat_entered.connect(enable_end_turn)
	character.combat_exited.connect(disable_end_turn)
	character.ability_deselected.connect(unsuspend_menu)
	update_abilities()
	if character.in_combat:
		enable_end_turn()
	else:
		disable_end_turn()

## Updates labels for HP, AP, and MP
func update_labels()->void:
	hp_label.text = "HP: "+str(character.cur_hp)
	ap_label.text = "AP: "+str(character.cur_ap)
	mp_label.text = "MP: "+str(character.cur_mp)

## Updates the abilities in the buttons
func update_abilities()->void:
	clear_abilities()
	var index: int = 0
	for ability in character.get_abilities():
		if index > 9:
			break
		add_ability(index, ability)
		abilities.append(ability)
		ability_buttons[index].disabled = false
		index += 1
	set_first_last_buttons()
	while index < 10:
		ability_buttons[index].disabled = true
		ability_buttons[index].focus_mode = Control.FOCUS_NONE
		index += 1

## Clears the abilities in the buttons
func clear_abilities()->void:
	abilities = []
	for button in ability_buttons:
		button.clear_ability()
#endregion
