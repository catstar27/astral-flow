extends Control
class_name CharacterSheet
## Class for a character sheet, which displays all character information

@export var name_labels: Array[Label] ## Array containing all Labels showing character name
@export var portrait_displays: Array[TextureRect] ## Array containing all TextureRects showing character portrait
@export var pronoun_labels: Array[Label] ## Array containing all Labels showing character pronouns
var character: Character ## Character this is tracking
signal opened ## Emitted when the sheet is opened
signal closed ## Emitted when the sheet is closed
signal skill_tree_requested(character: Character) ## Emitted to request opening a skill tree for tracked character

## Tracks given character with this sheet
func track_character(new_character: Character)->void:
	character = new_character
	for display in portrait_displays:
		display.texture = character.portrait
	for label in name_labels:
		label.text = character.display_name
	for label in pronoun_labels:
		label.text = character.pronouns
	open()

## Opens the character sheet
func open()->void:
	EventBus.broadcast("PAUSE", "NULLDATA")
	show()
	opened.emit()

## Closes the character sheet
func close()->void:
	EventBus.broadcast("UNPAUSE", "NULLDATA")
	hide()
	closed.emit()

## Requests opening the skill tree for the character this is tracking
func request_skill_tree()->void:
	skill_tree_requested.emit(character)
