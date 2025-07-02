@tool
extends VBoxContainer
class_name TabMenu
## Represents a menu with tabs that can be navigated with control display buttons
##
## Child control nodes represent the content of tabs, while the names are for the buttons

const tab_button_scn: PackedScene = preload("uid://cayiahrutslld") ## Tab button scene
@export var allow_loop: bool = true ## Allows the tabs to loop around
@export_range(3, 999, 1) var min_tabs: int ## Minimum number of tabs to display regardless of size
@onready var next_button: ControlDisplayButton = %NextButton ## Control Display Button that moves to next tab
@onready var prev_button: ControlDisplayButton = %PrevButton ## Control Display Button that moves to previous tab
@onready var ellipse_left: Button = %EllipseLeft ## Ellipse for the left side, when buttons are hidden
@onready var ellipse_right: Button = %EllipseRight ## Ellipse for the right side, when buttons are hidden
@onready var tab_button_container: HBoxContainer = %TabButtonContainer ## Container for tab buttons
var tab_buttons: Dictionary[Node, TabButton] ## Stores key/value pairs of button names and buttons
var cur_tab: Node ## The currently shown tab

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if get_child_count() > 1:
		cur_tab = get_children()[1]
	var children: Array[Node] = get_children()
	for node in get_children():
		if node != tab_button_container:
			remove_child(node)
	for child in tab_button_container.get_children():
		if child is TabButton:
			tab_button_container.remove_child(child)
			child.queue_free()
	set_children(children)

## Initializes the menu by re-adding the children after the node is ready
func set_children(children: Array[Node])->void:
	for child in children:
		if child != tab_button_container:
			add_child(child)
			child.set_owner(self)
	cur_tab = get_child(1)
	tab_buttons[cur_tab].button_pressed = true

## Creates and returns a tab button
func get_tab_button(node: Control)->TabButton:
	var button: TabButton = tab_button_scn.instantiate()
	button.connected_node = node
	return button

## Reorders the tab buttons to match the order of the tabs
func reorder()->void:
	if Engine.is_editor_hint() && is_node_ready():
		tab_button_container.move_child(next_button, tab_button_container.get_child_count()-1)
		tab_button_container.move_child(ellipse_right, tab_button_container.get_child_count()-2)
		for node in tab_buttons:
			tab_button_container.move_child(tab_buttons[node], node.get_index()+1)
			tab_buttons[node].show()
		crunch_tabs()

## Removes a tab button when the tab is removed from the scene
func remove_tab(node: Node)->void:
	if node is Control && is_node_ready():
		if node in tab_buttons:
			tab_button_container.remove_child(tab_buttons[node])
			tab_buttons[node].queue_free()
			tab_buttons.erase(node)
			crunch_tabs()

## Adds a tab button when a tab is added to the scene
func add_tab(node: Node)->void:
	if !is_node_ready():
		return
	if node is Control && node.name != "TabButtonContainer":
		if node not in tab_buttons:
			tab_buttons[node] = get_tab_button(node)
			tab_button_container.add_child(tab_buttons[node])
			tab_buttons[node].set_owner(self)
			tab_buttons[node].tab_shown.connect(tab_shown)
			if get_child_count() > 2:
				node.hide()
			elif Engine.is_editor_hint():
				cur_tab = node
			tab_button_container.move_child(next_button, tab_button_container.get_child_count()-1)
			tab_button_container.move_child(ellipse_right, tab_button_container.get_child_count()-2)
			crunch_tabs()

## Called when a tab is shown; hides all other tabs
func tab_shown(shown_tab: Node)->void:
	tab_buttons[cur_tab].set_pressed_no_signal(false)
	cur_tab.hide()
	cur_tab = shown_tab
	tab_buttons[cur_tab].set_pressed_no_signal(true)
	cur_tab.show()
	if cur_tab.has_method("select"):
		cur_tab.select()
	else:
		cur_tab.grab_focus()
	crunch_tabs()

## Selects the next tab
func next_tab()->void:
	if get_child_count() == 1:
		return
	tab_buttons[cur_tab].set_pressed_no_signal(false)
	cur_tab.hide()
	if cur_tab.get_index() != get_child_count()-1:
		cur_tab = get_children()[1+cur_tab.get_index()]
	elif allow_loop:
		cur_tab = get_children()[1]
	tab_buttons[cur_tab].set_pressed_no_signal(true)
	cur_tab.show()
	if cur_tab.has_method("select"):
		cur_tab.select()
	else:
		cur_tab.grab_focus()
	crunch_tabs()

## Selects the previous tab
func prev_tab()->void:
	if get_child_count() == 1:
		return
	tab_buttons[cur_tab].set_pressed_no_signal(false)
	cur_tab.hide()
	if cur_tab.get_index() != 1:
		cur_tab = get_children()[cur_tab.get_index()-1]
	elif allow_loop:
		cur_tab = get_children()[get_child_count()-1]
	tab_buttons[cur_tab].set_pressed_no_signal(true)
	cur_tab.show()
	if cur_tab.has_method("select"):
		cur_tab.select()
	else:
		cur_tab.grab_focus()
	crunch_tabs()

## Gets the width of the tab button container buttons
func get_tab_buttons_width()->int:
	var width: int = 0
	for child in tab_button_container.get_children():
		if child.visible:
			width += child.size.x
	return width

## Crunches the tabs to fit the custom_minimum_size's x value
func crunch_tabs()->void:
	for child in tab_button_container.get_children():
		child.show()
	ellipse_left.hide()
	ellipse_right.hide()
	if get_tab_buttons_width() > custom_minimum_size.x:
		var left: int = 1
		var right: int = get_child_count()-1
		var mid: int = cur_tab.get_index()
		while get_tab_buttons_width() > custom_minimum_size.x && visible_tab_button_count() > min_tabs:
			if right <= left || left >= right:
				printerr("Out of bounds in tab menu")
				return
			var left_distance: int = mid-left
			var right_distance: int = right-mid
			if left_distance > right_distance:
				tab_button_container.get_child(left+1).hide()
				ellipse_left.show()
				left += 1
			else:
				tab_button_container.get_child(right+1).hide()
				ellipse_right.show()
				right -= 1

## Returns the number of visible tab buttons
func visible_tab_button_count()->int:
	var count: int = 0
	for child in tab_button_container.get_children():
		if child is TabButton && child.visible:
			count += 1
	return count
