extends Node
## Autoload that manages saving and loading of all data other than settings

const save_file_folder: String = "user://saves/" ## Folder for save files
const main_scene: PackedScene = preload("res://misc/gameplay_managers/main.tscn") ## Filepath of main scene
var slot: String = "save1" ## Current save slot name
var loading: bool = false ## Whether the game is currently loading
var saving: bool = false ## Whether the game is currently saving
var in_combat: bool = false ## Whether the game is in a combat state
var num_ready: int = 0 ## Number of nodes that have finished saving or loading
signal node_readied ## Emitted when a node finishes saving or loading

func _ready() -> void:
	EventBus.subscribe("START_COMBAT", self, "started_combat")
	EventBus.subscribe("COMBAT_ENDED", self, "ended_combat")

## Called when combat starts
func started_combat(_data: Array[Character])->void:
	in_combat = true

## Called when combat ends
func ended_combat()->void:
	in_combat = false

## Checks if given save slot is blank
func is_slot_blank(check_slot: String)->bool:
	return !FileAccess.file_exists(save_file_folder+check_slot+"/Global.dat")

func _unhandled_input(event: InputEvent)->void:
	if event.is_action_pressed("quicksave"):
		save_data()
	if event.is_action_pressed("quickload"):
		load_data()

#region Delete and Reset
## Removes all non-autoload nodes and makes a new main scene
func reset_game()->Main:
	EventBus.broadcast("DELOAD", "NULLDATA")
	await get_tree().create_timer(.01).timeout
	var main: Main = main_scene.instantiate()
	get_tree().root.add_child(main)
	while !main.prepped:
		await main.ready
	return main

## Resets the given save slot to new game state
func reset_save(reset_slot: String)->void:
	if !DirAccess.dir_exists_absolute(save_file_folder+reset_slot):
		return
	delete_slot(reset_slot)
	saving = true
	loading = true
	Dialogic.VAR.reset()
	await reset_game()
	saving = false
	loading = false

## Deletes the given save slot
func delete_slot(remove_slot: String)->void:
	if !DirAccess.dir_exists_absolute(save_file_folder+remove_slot):
		return
	saving = true
	loading = true
	clear_dir(save_file_folder+remove_slot)
	DirAccess.remove_absolute(save_file_folder+remove_slot)
	saving = false
	loading = false

## Clears all files in the given directory
func clear_dir(dir: String)->void:
	for filename in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir+"/"+filename)
	for directory in DirAccess.get_directories_at(dir):
		clear_dir(dir+'/'+directory)
#endregion

#region Save and Load
## Loads the given map based on its loading method
func load_map(map: GameMap)->void:
	await map.load_map(save_file_folder+slot+'/')

## Loads the given player's data
func load_player(player: Player)->void:
	player.load_data(save_file_folder+slot+'/')

## Called when a node finishes saving or loading
func readied(node: Node)->void:
	if saving:
		node.saved.disconnect(readied)
	else:
		node.loaded.disconnect(readied)
	num_ready += 1
	node_readied.emit()

## Saves the game, creating the necessary folders if missing
func save_data(quiet_save: bool = false)->void:
	if saving || loading:
		return
	if in_combat:
		EventBus.broadcast("PRINT_LOG", "Cannot Save When in Danger!")
		return
	saving = true
	if !DirAccess.dir_exists_absolute(save_file_folder):
		DirAccess.make_dir_absolute(save_file_folder)
	if !DirAccess.dir_exists_absolute(save_file_folder+slot):
		DirAccess.make_dir_absolute(save_file_folder+slot)
	var file: FileAccess = FileAccess.open(save_file_folder+slot+"/Global.dat", FileAccess.WRITE)
	file.store_var("CURRENT_MAP="+NavMaster.map.scene_file_path)
	for variable in Dialogic.VAR.variables():
		file.store_var(variable)
		file.store_var(Dialogic.VAR.get_variable(variable))
	file.store_var("END_OF_SAVE_DATA")
	file.close()
	num_ready = 0
	var num_to_save: int = 0
	for node in get_tree().get_nodes_in_group("Persist"):
		if !node.has_method("save_data"):
			printerr("Persistent node"+node.name+"missing save data function")
		node.saved.connect(readied)
		num_to_save += 1
		node.save_data(save_file_folder+slot+'/')
	while num_ready < num_to_save:
		await node_readied
	await NavMaster.map.save_map(save_file_folder+slot+'/')
	if !quiet_save:
		EventBus.broadcast("PRINT_LOG", "Saved!")
	saving = false

## Loads the game
func load_data()->void:
	if !DirAccess.dir_exists_absolute(save_file_folder+slot):
		printerr("Save Folder Not Found")
		return
	if !FileAccess.file_exists(save_file_folder+slot+"/Global.dat"):
		printerr("Save File Not Found in Folder")
		return
	if loading || saving:
		return
	loading = true
	in_combat = false
	var file: FileAccess = FileAccess.open(save_file_folder+slot+"/Global.dat", FileAccess.READ)
	var cur_map: String = file.get_var().split('=', true, 1)[1]
	var main: Node2D = await reset_game()
	var variable: String = file.get_var()
	while variable != "END_OF_SAVE_DATA":
		Dialogic.VAR.set_variable(variable, file.get_var())
		variable = file.get_var()
	file.close()
	num_ready = 0
	var num_to_load: int = 0
	for node in get_tree().get_nodes_in_group("Persist"):
		if !node.has_method("load_data"):
			printerr("Persistent node"+node.name+"missing load data function")
		node.loaded.connect(readied)
		num_to_load += 1
		node.load_data(save_file_folder+slot+'/')
	while num_ready < num_to_load:
		await node_readied
	await main.load_map(cur_map)
	EventBus.broadcast("LOADED", "NULLDATA")
	EventBus.broadcast("PRINT_LOG", "Loaded!")
	loading = false
#endregion
