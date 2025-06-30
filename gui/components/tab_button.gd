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
		toggled.connect(show_connected)
signal tab_shown(tab: Control) ## Emitted when the connected node is shown

## Resets the button text
func reset_name()->void:
	text = connected_node.name
	name = connected_node.name+"Button"

## Shows connected node
func show_connected(_on)->void:
	tab_shown.emit(connected_node)
