@icon("node_name_label_icon.svg")
extends Label

class_name DialogicNode_NameLabel

# If true, the label will be hidden if no character speaks.
@export var hide_when_empty := true
@export var empty_text := ""
@export var name_label_root: Node = self
@export var use_character_color := true

func _ready() -> void:
	add_to_group('dialogic_name_label')
	if hide_when_empty:
		name_label_root.visible = false
	text = ""


func _set(property, what):
	if property == 'text' and typeof(what) == TYPE_STRING:
		text = what
		if hide_when_empty:
			name_label_root.visible = !what.is_empty()
		elif what.is_empty():
			text = empty_text
		else:
			name_label_root.show()
		return true
