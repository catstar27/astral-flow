extends Control
class_name PartyDisplay
## A menu that displays the QuickInfo for all active party members
##
## Also allows quick access of character sheets

@export var party_quick_info: Array[QuickInfo] ## Party member quick info nodes
signal request_open_character_sheet(character: Character) ## Signal emitted to open a character sheet
signal opened ## Emitted when opened
signal closed ## Emitted when closed

## Disables focus and mouse detection
func disable()->void:
	for button in %PartyButtonContainer.get_children():
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE

## Enables focus and mouse detection
func enable()->void:
	for button in %PartyButtonContainer.get_children():
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.focus_mode = Control.FOCUS_ALL

## Focuses the first available party member
func focus_first()->void:
	party_quick_info[0].get_parent().focus_mode = Control.FOCUS_ALL
	party_quick_info[0].get_parent().grab_focus()

## Updates the party display by removing and adding QuickInfos
func update_display()->void:
	var index: int = 0
	for party_member in get_tree().get_nodes_in_group("PartyMember"):
		var info: QuickInfo = party_quick_info[index]
		index += 1
		info.track_character(party_member)
		info.show()
	while index < 4:
		party_quick_info[index].get_parent().hide()
		index += 1
	await get_tree().process_frame
	%PartyButtonContainer.reset_size()

## Opens the menu
func open_menu()->void:
	update_display()
	show()
	party_quick_info[0].get_parent().grab_focus()
	for i in range(0,4):
		party_quick_info[i].check_and_show()
		party_quick_info[i].get_parent().custom_minimum_size = party_quick_info[i].size+Vector2.ONE*12
	await get_tree().process_frame
	position.y = 49
	position.x = -%PartyButtonContainer.size.x
	opened.emit()

## Closes the menu
func close_menu()->void:
	await create_tween().tween_property(self, "position", Vector2(0,position.y), .2).finished
	hide()
	closed.emit()

func _on_party_1_button_down() -> void:
	request_open_character_sheet.emit(party_quick_info[0].character)
	party_quick_info[0].modulate = Color.DIM_GRAY

func _on_party_2_button_down() -> void:
	request_open_character_sheet.emit(party_quick_info[1].character)
	party_quick_info[1].modulate = Color.DIM_GRAY

func _on_party_3_button_down() -> void:
	request_open_character_sheet.emit(party_quick_info[2].character)
	party_quick_info[2].modulate = Color.DIM_GRAY

func _on_party_4_button_down() -> void:
	request_open_character_sheet.emit(party_quick_info[3].character)
	party_quick_info[3].modulate = Color.DIM_GRAY

func _on_party_1_button_up() -> void:
	party_quick_info[0].modulate = Color.WHITE

func _on_party_2_button_up() -> void:
	party_quick_info[1].modulate = Color.WHITE

func _on_party_3_button_up() -> void:
	party_quick_info[2].modulate = Color.WHITE

func _on_party_4_button_up() -> void:
	party_quick_info[3].modulate = Color.WHITE
