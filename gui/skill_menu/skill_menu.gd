extends MarginContainer
class_name SkillMenu
## Menu showing all skill trees and their associated skills

var character: Character ## Character to show skills for
signal opened ## Emitted when this menu is opened
signal closed ## Emitted when this menu is closed

## Opens this menu
func open(new_character: Character)->void:
	character = new_character
	show()
	opened.emit()

## Closes this menu
func close()->void:
	hide()
	closed.emit()
