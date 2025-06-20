@tool
extends Button
class_name TabButton
## Button corresponding to a tab in a TabMenu
##
## Links to a Control node

var connected_node: Control: ## The node this button tracks
	set(node):
		connected_node = node
		name = connected_node.name+"Button"
		text = connected_node.name
		connected_node.renamed.connect(reset_name)
		connected_node.visibility_changed.connect(on_connected_visibility_changed)
		toggled.connect(toggle_connected_visibility)
signal tab_hidden(tab: Control) ## Emitted when the connected node is hidden
signal tab_shown(tab: Control) ## Emitted when the connected node is shown

## Resets the button text
func reset_name()->void:
	text = connected_node.name
	name = connected_node.name+"Button"

## Emits signals when the connected node is hidden or shown
func on_connected_visibility_changed()->void:
	if connected_node.visible:
		set_pressed_no_signal(true)
		tab_shown.emit(connected_node)
	else:
		tab_hidden.emit(connected_node)

## Toggles visibility of connected node; called when toggled
func toggle_connected_visibility(on: bool)->void:
	if on:
		connected_node.show()
	else:
		connected_node.hide()
