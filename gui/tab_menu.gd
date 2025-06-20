@tool
extends VBoxContainer
class_name TabMenu
## Represents a menu with tabs that can be navigated with control display buttons
##
## Child control nodes represent the content of tabs, while the names are for the buttons

const tab_button_scn: PackedScene = preload("uid://cayiahrutslld") ## Tab button scene
@onready var next_button: ControlDisplayButton = %NextButton ## Control Display Button that moves to next tab
@onready var prev_button: ControlDisplayButton = %PrevButton ## Control Display Button that moves to previous tab
@onready var tab_button_container: HBoxContainer = %TabButtonContainer ## Container for tab buttons
var adding_node: bool = false ## Whether a node is being added
var removing_node: bool = false ## Whether a node is being removed
var tab_buttons: Dictionary[Node, TabButton] ## Stores key/value pairs of button names and buttons
var cur_tab: Node ## The currently shown tab

func _ready() -> void:
	if !Engine.is_editor_hint():
		for node in tab_button_container.get_children():
			if node != prev_button && node != next_button:
				node.queue_free()
		for node in get_children():
			remove_child(node)
			add_child(node)
		cur_tab = get_children()[1]
		tab_buttons[cur_tab].button_pressed = true

## Creates and returns a tab button
func get_tab_button(node: Control)->TabButton:
	var button: TabButton = tab_button_scn.instantiate()
	button.connected_node = node
	return button

## Reorders the tab buttons to match the order of the tabs
func reorder()->void:
	if Engine.is_editor_hint() && !adding_node && !removing_node:
		for node in tab_buttons:
			tab_button_container.move_child(tab_buttons[node], node.get_index()+1)
		tab_button_container.remove_child(next_button)
		tab_button_container.add_child(next_button)
		next_button.owner = self

## Removes a tab button when the tab is removed from the scene
func remove_tab(node: Node)->void:
	while !is_node_ready():
		await ready
	if node is Control:
		if node in tab_buttons:
			removing_node = true
			tab_button_container.remove_child(tab_buttons[node])
			tab_buttons[node].queue_free()
			tab_buttons.erase(node)
			removing_node = false

## Adds a tab button when a tab is added to the scene
func add_tab(node: Node)->void:
	while !is_node_ready():
		await ready
	if node is Control && node.name != "TabButtonContainer":
		if node not in tab_buttons:
			adding_node = true
			tab_buttons[node] = get_tab_button(node)
			tab_button_container.add_child(tab_buttons[node])
			tab_buttons[node].owner = self
			if get_child_count() > 2:
				node.hide()
			else:
				cur_tab = node
				tab_buttons[node].button_pressed = true
			tab_button_container.remove_child(next_button)
			tab_button_container.add_child(next_button)
			next_button.owner = self
			tab_buttons[node].tab_shown.connect(tab_shown)
			tab_buttons[node].tab_hidden.connect(tab_hidden)
			adding_node = false

## Called when a tab is shown; hides all other tabs
func tab_shown(shown_tab: Node)->void:
	while !is_node_ready():
		await ready
	cur_tab = shown_tab
	for tab in tab_buttons.keys():
		if tab != shown_tab:
			tab.hide()
			tab_buttons[tab].set_pressed_no_signal(false)

## Called when a tab is hidden; selects the next tab if the current tab is the hidden tab
func tab_hidden(hidden_tab: Node)->void:
	if cur_tab == hidden_tab:
		next_tab()

## Selects the next tab
func next_tab()->void:
	if get_child_count() == 1:
		return
	if cur_tab.get_index() != get_child_count()-1:
		cur_tab = get_children()[1+cur_tab.get_index()]
	else:
		cur_tab = get_children()[1]
	tab_buttons[cur_tab].button_pressed = true

## Selects the previous tab
func prev_tab()->void:
	if get_child_count() == 1:
		return
	if cur_tab.get_index() != 1:
		cur_tab = get_children()[cur_tab.get_index()-1]
	else:
		cur_tab = get_children()[get_child_count()-1]
	tab_buttons[cur_tab].button_pressed = true
