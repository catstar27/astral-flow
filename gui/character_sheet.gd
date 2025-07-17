extends Control
class_name CharacterSheet
## Class for a character sheet, which displays all character information

@export var star_stats_container: VBoxContainer ## Container for star stat labels
@export var other_stats_container: VBoxContainer ## Container for all other stats
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
	for label in star_stats_container.get_children():
		label.text = label.name.replace('_', ' ')+": "
		label.text += str(character.star_stats[label.name.to_lower()]+character.star_stat_mods[label.name.to_lower()])
		if character.star_stat_mods[label.name.to_lower()] > 0:
			label.text += " (+"+str(character.star_stat_mods[label.name.to_lower()])+")"
		elif character.star_stat_mods[label.name.to_lower()] < 0:
			label.text += " ("+str(character.star_stat_mods[label.name.to_lower()])+")"
	for label in other_stats_container.get_children():
		label.text = label.name.replace('_', ' ')+": "
		if label.name == "Max_HP":
			label.text += str(character.cur_hp)+"/"
		elif label.name == "Max_AP":
			label.text += str(character.cur_ap)+"/"
		elif label.name == "Max_MP":
			label.text += str(character.cur_mp)+"/"
		label.text += str(character.base_stats[label.name.to_lower()]+character.stat_mods[label.name.to_lower()])
		if character.stat_mods[label.name.to_lower()] > 0:
			label.text += " (+"+str(character.stat_mods[label.name.to_lower()])+")"
		elif character.stat_mods[label.name.to_lower()] < 0:
			label.text += " ("+str(character.stat_mods[label.name.to_lower()])+")"
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
