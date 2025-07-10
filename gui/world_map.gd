extends VBoxContainer
class_name WorldMap
## Represents the menu for the world map grid
##
## Responsible for fast travel as well

signal opened ## Emitted when the menu opens
signal closed ## Emitted when the menu closes

## Shows the menu and emits the signal for opening it
func open()->void:
	show()
	EventBus.broadcast("PAUSE", "NULLDATA")
	opened.emit()

## Hides the menu and emits the signal for closing it
func close()->void:
	EventBus.broadcast("UNPAUSE", "NULLDATA")
	hide()
	closed.emit()
