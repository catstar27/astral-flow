extends Control
class_name HUD

@onready var char_info: CharInfo = %CharInfo

func setup()->void:
	char_info.hide()
	GlobalRes.selection_cursor.selection_changed.connect(set_char_info)

func set_char_info(selected: Node2D)->void:
	if selected is not Character && selected is not Ability || selected == null:
		char_info.hide()
	elif selected is Character:
		char_info.set_character(selected)
		char_info.show()
	else:
		char_info.set_character(selected.user)
		char_info.show()
