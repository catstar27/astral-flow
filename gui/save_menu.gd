extends Control
class_name SaveMenu
## Menu that displays save files and allows saving or loading, depending on the mode selected on opening

var save_mode: bool = true ## Whether this is in save or load mode

## Opens the menu in save mode
func open_save_mode()->void:
	save_mode = true

## Opens the menu in load mode
func open_load_mode()->void:
	save_mode = false
