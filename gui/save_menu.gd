extends Control
class_name SaveMenu
## Menu that displays save files and allows saving or loading, depending on the mode selected on opening

@onready var file_tree: Tree = %FileTree ## Tree for the files
@onready var name_label: Label = %NameLabel ## Label showing save file name
@onready var date_label: Label = %DateLabel ## Label showing date of save file
@onready var size_label: Label = %SizeLabel ## Label showing file size of save file
@onready var delete_button: ControlDisplayButton = %DeleteButton ## Button to delete this file
@onready var confirm_menu: ConfirmMenu = %ConfirmMenu ## Menu for confirmations
@onready var text_entry_menu: TextEntryMenu = %TextEntryMenu ## Menu for text entries
var save_mode: bool = true ## Whether this is in save or load mode
var file_tree_prepped: bool = false ## Whether the file tree has been prepared
signal opened ## Emitted when opened
signal closed_save ## Emitted when closed in save mode
signal closed_load ## Emitted when closed in load mode

func _unhandled_input(event: InputEvent) -> void:
	if !file_tree_prepped:
		return
	if event.is_action_pressed("down"):
		select_next()
	elif event.is_action_pressed("up"):
		select_prev()
	elif event.is_action_pressed("interact"):
		if file_tree.get_selected().get_child_count() > 0:
			file_tree.get_selected().collapsed = !file_tree.get_selected().collapsed
		else:
			file_tree.button_clicked.emit(file_tree.get_selected(), 0, 0, 0)

## Selects the next file or folder in the tree
func select_next()->void:
	var next: TreeItem = file_tree.get_selected().get_next()
	if file_tree.get_selected().get_child_count() > 0:
		next = file_tree.get_selected().get_child(0)
	if next == null && file_tree.get_selected().get_parent() != file_tree.get_root():
		next = file_tree.get_selected().get_parent().get_next()
	if next != null:
		next.select(0)
	file_tree.scroll_to_item(next)

## Selects the previous file or folder in the tree
func select_prev()->void:
	var prev: TreeItem = file_tree.get_selected().get_prev()
	if prev != null && prev.get_child_count() > 0:
		prev = prev.get_child(-1)
	if prev == null && file_tree.get_selected().get_parent() != file_tree.get_root():
		prev = file_tree.get_selected().get_parent()
	if prev != null:
		prev.select(0)
	file_tree.scroll_to_item(prev)

## Opens the menu in save mode
func open_save_mode()->void:
	save_mode = true
	prep_file_tree()
	show()
	file_tree.set_selected(file_tree.get_root().get_first_child(), 0)
	opened.emit()

## Opens the menu in load mode
func open_load_mode()->void:
	save_mode = false
	prep_file_tree()
	show()
	file_tree.set_selected(file_tree.get_root().get_first_child(), 0)
	opened.emit()

## Closes the menu
func close()->void:
	file_tree_prepped = false
	name_label.text = "Name: N/A"
	date_label.text = "Date: N/A"
	size_label.text = "Size: N/A"
	hide()
	if save_mode:
		closed_save.emit()
	else:
		closed_load.emit()

## Updates labels to show info about the file (if applicable)
func update_info_labels()->void:
	var filepath: String = SaveLoad.save_file_folder+file_tree.get_selected().get_parent().get_text(0)
	filepath += '/'+file_tree.get_selected().get_text(0)
	var file: FileAccess = null
	if FileAccess.file_exists(filepath):
		file = FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		name_label.text = "Name: N/A"
		date_label.text = "Date: N/A"
		size_label.text = "Size: N/A"
	else:
		name_label.text = "Name: "+file_tree.get_selected().get_text(0).left(-4)
		date_label.text = "Date: "+str(Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(filepath)))
		size_label.text = "Size: "+str(float(file.get_length())/1000)+" KB"

## Prepares the file tree
func prep_file_tree()->void:
	var directory: DirAccess = DirAccess.open(SaveLoad.save_file_folder)
	file_tree.clear()
	var root: TreeItem = file_tree.create_item(null)
	for dir in directory.get_directories():
		var dir_item: TreeItem = file_tree.create_item(root)
		dir_item.set_text(0, dir)
		for file in DirAccess.get_files_at(SaveLoad.save_file_folder+"/"+dir):
			var file_item: TreeItem = file_tree.create_item(dir_item)
			file_item.set_text(0, file)
		if save_mode:
			var new_file_item: TreeItem = file_tree.create_item(dir_item)
			new_file_item.set_text(0, "New File")
			new_file_item.add_button(0, Texture2D.new())
	if save_mode:
		var new_save_item: TreeItem = file_tree.create_item(root)
		new_save_item.set_text(0, "New Folder")
		new_save_item.add_button(0, Texture2D.new())
	file_tree_prepped = true

## Process a file tree button being pressed
func process_file_tree_button_press(item: TreeItem, column: int, _id: int, _mouse_button_index: int) -> void:
	var button_text: String = item.get_text(column)
	if button_text == "New Folder":
		text_entry_menu.info_label.text = "Enter New Folder Name"
		text_entry_menu.open()
		%Menu.hide()
		var data: Array = await text_entry_menu.text_submitted
		if data[0]:
			for child in item.get_parent().get_children():
				if child.get_text(0) == data[1]:
					return
			var new_item: TreeItem = file_tree.get_root().create_child(item.get_index())
			new_item.set_text(0, data[1])
			var new_file_item: TreeItem = file_tree.create_item(new_item)
			new_file_item.set_text(0, "New File")
			new_file_item.add_button(0, Texture2D.new())
			DirAccess.make_dir_absolute(SaveLoad.save_file_folder+data[1])
	elif button_text == "New File":
		text_entry_menu.info_label.text = "Enter New File Name"
		text_entry_menu.open()
		%Menu.hide()
		var data: Array = await text_entry_menu.text_submitted
		if data[0]:
			for child in item.get_parent().get_children():
				if child.get_text(0) == data[1]+".dat":
					return
			var new_item: TreeItem = item.get_parent().create_child(item.get_index())
			new_item.set_text(0, data[1]+".dat")
			new_item.add_button(0, Texture2D.new())
			SaveLoad.save_data(data[1], item.get_parent().get_text(0))
	else:
		if save_mode:
			SaveLoad.save_data(button_text.left(-4), item.get_parent().get_text(0))
			update_info_labels()
		else:
			SaveLoad.load_data(button_text.left(-4), item.get_parent().get_text(0))

## Deletes the current save file or folder
func delete_current()->void:
	var tree_delete: TreeItem = file_tree.get_selected()
	var is_folder: bool = tree_delete.get_parent() == file_tree.get_root()
	confirm_menu.confirm_label.text = "Are you sure you want to delete\nthe save "
	if is_folder:
		confirm_menu.confirm_label.text += "folder '"+tree_delete.get_text(0)+"'?"
	else:
		confirm_menu.confirm_label.text += "file '"+tree_delete.get_text(0)+"'?"
	confirm_menu.show()
	%Menu.hide()
	if await confirm_menu.confirmation_given:
		if is_folder:
			SaveLoad.delete_slot(tree_delete.get_text(0))
			if tree_delete.get_child_count() > 1:
				select_next()
			else:
				select_next()
				select_next()
			file_tree.get_root().remove_child(tree_delete)
		else:
			SaveLoad.delete_file(tree_delete.get_text(0), tree_delete.get_parent().get_text(0))
			select_next()
			tree_delete.get_parent().remove_child(tree_delete)

## Renames the current save file or folder
func rename_current()->void:
	var tree_rename: TreeItem = file_tree.get_selected()
	var is_folder: bool = tree_rename.get_parent() == file_tree.get_root()
	text_entry_menu.info_label.text = "Enter New Name"
	text_entry_menu.open()
	%Menu.hide()
	var data: Array = await text_entry_menu.text_submitted
	if data[0]:
		if is_folder:
			for child in tree_rename.get_parent().get_children():
				if child.get_text(0) == data[1]:
					return
			if SaveLoad.recent_slot == tree_rename.get_text(0):
				SaveLoad.recent_slot = data[1]
			DirAccess.rename_absolute(SaveLoad.save_file_folder+tree_rename.get_text(0), SaveLoad.save_file_folder+data[1])
			tree_rename.set_text(0, data[1])
		else:
			for child in tree_rename.get_parent().get_children():
				if child.get_text(0) == data[1]+".dat":
					return
			var folder: String = SaveLoad.save_file_folder+tree_rename.get_parent().get_text(0)+'/'
			DirAccess.rename_absolute(folder+tree_rename.get_text(0), folder+data[1]+".dat")
			tree_rename.set_text(0, data[1]+".dat")
			update_info_labels()
