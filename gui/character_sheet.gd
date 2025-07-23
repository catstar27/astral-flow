extends Control
class_name CharacterSheet
## Class for a character sheet, which displays all character information

const res_button: PackedScene = preload("uid://cavlvpuhv8qc7")
@export var item_list: VBoxContainer ## Container for inventory items
@export var item_description_box: PanelContainer ## PanelContainer showing item description
@export var breakthroughs_list: VBoxContainer ## Container for breakthrough progress
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
func open(starting_tab: String = "Stats")->void:
	EventBus.broadcast("PAUSE", "NULLDATA")
	while %TabMenu.cur_tab.name != starting_tab:
		%TabMenu.next_tab()
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
	populate_item_box()
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

## Fills the item box
func populate_item_box()->void:
	for child in item_list.get_children():
		if child is ResourceButton:
			item_list.remove_child(child)
			child.queue_free()
	for item in character.item_manager.item_dict.keys():
		var button: ResourceButton = res_button.instantiate()
		button.resource = item
		button.text = item.display_name
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed_resource.connect(use_item)
		item_list.add_child(button)
	item_list.move_child(item_description_box, -1)
	if item_list.get_child_count() > 2:
		item_description_box.show()
		item_list.get_child(0).hide()
		if item_list.is_visible_in_tree():
			item_list.get_child(1).grab_focus()
	else:
		item_description_box.hide()
		item_list.get_child(0).show()

## Attempts to use an item
func use_item(item: Item)->void:
	close()
	character.item_manager.activate_item(item)
	await get_tree().process_frame
	open("Inventory")
	while Dialogic.current_timeline != null:
		await Dialogic.timeline_ended
	if item_list.get_child_count() > 2 && item_list.is_visible_in_tree():
		item_list.get_child(1).grab_focus()

func _on_tab_menu_tab_changed() -> void:
	var tab_name: String
	for tab in %TabMenu.get_children():
		if tab.is_visible_in_tree() && tab.name != "TabButtonContainer":
			tab_name = tab.name
			break
	if tab_name == "Inventory" && item_list.get_child_count() > 2:
		item_list.get_child(1).grab_focus()
	elif tab_name == "Breakthroughs" && breakthroughs_list.get_child_count() > 1:
		breakthroughs_list.get_child(0).hide()
		breakthroughs_list.get_child(1).grab_focus()
	else:
		focus_mode = Control.FOCUS_ALL
		grab_focus()
		release_focus()
		focus_mode = Control.FOCUS_NONE
