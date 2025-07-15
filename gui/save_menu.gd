extends Control
class_name SaveMenu
## Menu that displays save files and allows saving or loading, depending on the mode selected on opening

@onready var file_tree: Tree = %FileTree ## Tree for the files
@onready var name_label: Label = %NameLabel ## Label showing save file name
@onready var date_label: Label = %DateLabel ## Label showing date of save file
@onready var size_label: Label = %SizeLabel ## Label showing file size of save file
@onready var save_button: ControlDisplayButton = %SaveButton ## Button to save to this file
@onready var load_button: ControlDisplayButton = %SaveButton ## Button to load this file
@onready var delete_button: ControlDisplayButton = %DeleteButton ## Button to delete this file
var save_mode: bool = true ## Whether this is in save or load mode
var file_tree_prepped: bool = false ## Whether the file tree has been prepared
signal opened ## Emitted when opened
signal closed ## Emitted when closed

func _unhandled_input(event: InputEvent) -> void:
	if !file_tree_prepped:
		return
	if event.is_action("down"):
		var next: TreeItem = file_tree.get_selected().get_next()
		if next != null:
			next.select(0)
	elif event.is_action("up"):
		var prev: TreeItem = file_tree.get_selected().get_prev()
		if prev != null:
			prev.select(0)

## Opens the menu in save mode
func open_save_mode()->void:
	save_mode = true
	save_button.show()
	prep_file_tree()
	show()
	file_tree.set_selected(file_tree.get_root().get_first_child(), 0)
	opened.emit()

## Opens the menu in load mode
func open_load_mode()->void:
	save_mode = false
	load_button.show()
	prep_file_tree()
	show()
	opened.emit()

## Closes the menu
func close()->void:
	file_tree_prepped = false
	name_label.text = "Name: N/A"
	date_label.text = "Date: N/A"
	size_label.text = "Size: N/A"
	save_button.hide()
	load_button.hide()
	hide()
	closed.emit()

## Prepares the file tree
func prep_file_tree()->void:
	var directory: DirAccess = DirAccess.open(SaveLoad.save_file_folder)
	file_tree.clear()
	var root: TreeItem = file_tree.create_item(null)
	for dir in directory.get_directories():
		var dir_item: TreeItem = file_tree.create_item(root)
		dir_item.set_text(0, dir)
	if save_mode:
		var new_save_item: TreeItem = file_tree.create_item(root)
		new_save_item.set_text(0, "New Folder")
		new_save_item.add_button(0, Texture2D.new())
	file_tree_prepped = true
