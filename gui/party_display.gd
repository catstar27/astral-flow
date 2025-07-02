extends VBoxContainer
class_name PartyDisplay
## A menu that displays the QuickInfo for all active party members
##
## Also allows quick access of character sheets

func _ready() -> void:
	EventBus.subscribe("PARTY_CHANGED", self, "update_display")

## Updates the party display by removing and adding QuickInfos
func update_display()->void:
	var index: int = 0
	for party_member in get_tree().get_nodes_in_group("PartyMember"):
		var info: QuickInfo = get_child(index).get_child(0)
		index += 1
		info.track_character(party_member)
		info.show()
	while index < 4:
		get_child(index).hide()
		index += 1

## Opens the menu
func open_menu()->void:
	show()
	get_child(0).grab_focus()
	for i in range(0,4):
		get_child(i).get_child(0).check_and_show()
		get_child(i).custom_minimum_size = get_child(i).get_child(0).size
