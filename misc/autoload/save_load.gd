extends Node

var slot: String = "save1"
var save_file_folder: String = "user://saves/"
var main_scene: PackedScene = preload("res://misc/gameplay_managers/main.tscn")
var loading: bool = false
var saving: bool = false
var in_combat: bool = false

class SaveData:
	var data: Array
	var id: String
	func _to_string() -> String:
		return id

class SaveMarker:
	var id: String
	func _to_string()->String:
		return id

func _ready() -> void:
	EventBus.subscribe("START_COMBAT", self, "started_combat")
	EventBus.subscribe("COMBAT_ENDED", self, "ended_combat")

func started_combat(_data: Array[Character])->void:
	in_combat = true

func ended_combat()->void:
	in_combat = false

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

func delete_slot(remove_slot: String)->void:
	if !DirAccess.dir_exists_absolute(save_file_folder+remove_slot):
		return
	saving = true
	loading = true
	for filename in DirAccess.get_files_at(save_file_folder+remove_slot):
		DirAccess.remove_absolute(save_file_folder+remove_slot+"/"+filename)
	DirAccess.remove_absolute(save_file_folder+remove_slot)
	saving = false
	loading = false

func is_slot_blank(check_slot: String)->bool:
	return !FileAccess.file_exists(save_file_folder+check_slot+"/Global.dat")

func save_data(quiet_save: bool = false)->void:
	if saving || loading:
		return
	if in_combat:
		EventBus.broadcast("PRINT_LOG", "Cannot Save When in Danger!")
		return
	if NavMaster.map.map_name == "Global":
		printerr("Map Name Collides with Global Saves")
		return
	saving = true
	if !DirAccess.dir_exists_absolute(save_file_folder):
		DirAccess.make_dir_absolute(save_file_folder)
	if !DirAccess.dir_exists_absolute(save_file_folder+slot):
		DirAccess.make_dir_absolute(save_file_folder+slot)
	var file: FileAccess = FileAccess.open(save_file_folder+slot+"/Global.dat", FileAccess.WRITE)
	NavMaster.map.save_map(save_file_folder+slot+'/')
	file.store_var("CURRENT_MAP="+NavMaster.map.scene_file_path)
	for node in get_tree().get_nodes_in_group("Persist"):
		if !node.has_method("save_data"):
			printerr("Persistent node"+node.name+"missing save data function")
		file.store_var("\n@SAVE_MARKER@"+node.name)
		await node.save_data(file)
	file.store_var("DIALOGIC_VARS")
	for variable in Dialogic.VAR.variables():
		file.store_var(Dialogic.VAR.get_variable(variable))
	file.store_var("END_OF_SAVE_DATA")
	file.close()
	if !quiet_save:
		EventBus.broadcast("PRINT_LOG", "Saved!")
	saving = false

func load_data()->void:
	if !DirAccess.dir_exists_absolute(save_file_folder+slot):
		printerr("Save Folder Not Found")
		return
	if !FileAccess.file_exists(save_file_folder+slot+"/Global.dat"):
		printerr("Save File Not Found in Folder")
		return
	if loading:
		return
	loading = true
	AudioServer.set_bus_mute(0, true)
	var file: FileAccess = FileAccess.open(save_file_folder+slot+"/Global.dat", FileAccess.READ)
	var cur_map: String = file.get_var().split('=', true, 1)[1]
	var main: Node2D = await reset_game()
	await main.load_map(cur_map)
	var target: String = file.get_var()
	while target != null and target != "DIALOGIC_VARS":
		target = parse_name(target)
		for node in get_tree().get_nodes_in_group("Persist"):
			if node.name == target:
				if !node.has_method("load_data"):
					printerr("Persistent node"+node.name+"missing load data function")
				await node.load_data(file)
		target = file.get_var()
	for variable in Dialogic.VAR.variables():
		Dialogic.VAR.set_variable(variable, file.get_var())
	file.close()
	EventBus.broadcast("LOADED", "NULLDATA")
	EventBus.broadcast("PRINT_LOG", "Loaded!")
	AudioServer.set_bus_mute(0, false)
	loading = false

func reset_game()->Node2D:
	EventBus.broadcast("DELOAD", "NULLDATA")
	await get_tree().create_timer(.01).timeout
	var main = main_scene.instantiate()
	get_tree().root.add_child(main)
	while !main.prepped:
		await main.ready
	return main

func load_map(map: GameMap)->void:
	await map.load_map(save_file_folder+slot+'/')

func parse_name(line: String)->String:
	return line.split("@SAVE_MARKER@")[1]
