extends PanelContainer
class_name TextEntryMenu
## Menu with a text entry that emits a signal with entered text when closed

const restricted_characters: Array[String] = []
@onready var text_input: LineEdit = %TextInput ## Text input for the menu
@onready var info_label: Label = %InfoLabel ## Label showing info about text to be entered
var prev_text: String = "" ## Previously entered text

signal text_submitted(submitted: bool, text: String) ## Emitted with the text_input signal of the same name

## Opens this menu
func open()->void:
	show()
	text_input.grab_focus()

func _on_text_input_text_submitted(new_text: String) -> void:
	text_submitted.emit(true, new_text)
	hide()
	text_input.text = ""

func _on_cancel_button_pressed() -> void:
	text_submitted.emit(false, "")
	hide()
	text_input.text = ""

func _on_text_input_text_changed(new_text: String) -> void:
	if new_text.length() < 2:
		prev_text = new_text
		return
	var prev_caret_pos: int = text_input.caret_column
	if new_text.left(-1) != prev_text && !new_text.is_subsequence_of(prev_text):
		text_input.text = prev_text
	elif new_text.right(1) == ' ':
		text_input.text = prev_text+'_'
		prev_text = text_input.text
	else:
		if !new_text.is_valid_filename():
			text_input.text = prev_text
		else:
			prev_text = text_input.text
	text_input.caret_column = prev_caret_pos
