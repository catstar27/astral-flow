extends Node

var slot: String = "save1"
var save_file_folder: String = "user://saves/"
var main_scene: PackedScene = preload("res://misc/main.tscn")
var loading: bool = false
var saving: bool = false
signal load_ready_now

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
	EventBus.subscribe("MAP_LOADED", self, "load_ready")

func save_data()->void:
	if saving:
		return
	saving = true
	if !DirAccess.dir_exists_absolute(save_file_folder):
		DirAccess.make_dir_absolute(save_file_folder)
	if !DirAccess.dir_exists_absolute(save_file_folder+slot):
		DirAccess.make_dir_absolute(save_file_folder+slot)
	var file: FileAccess = FileAccess.open(save_file_folder+slot+"/global_persist", FileAccess.WRITE)
	NavMaster._map.save_map(save_file_folder+slot+'/')
	file.store_var("CURRENT_MAP="+NavMaster._map.scene_file_path)
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
	EventBus.broadcast(EventBus.Event.new("PRINT_LOG", "Saved!"))
	saving = false

func load_data()->void:
	if !DirAccess.dir_exists_absolute(save_file_folder+slot):
		printerr("Save Folder Not Found")
		return
	if !FileAccess.file_exists(save_file_folder+slot+"/global_persist"):
		printerr("Save File Not Found in Folder")
		return
	if loading:
		return
	loading = true
	var file: FileAccess = FileAccess.open(save_file_folder+slot+"/global_persist", FileAccess.READ)
	var cur_map: String = file.get_var().split('=', true, 1)[1]
	EventBus.broadcast(EventBus.Event.new("DELOAD", "NULLDATA"))
	await get_tree().create_timer(.01).timeout
	get_tree().root.add_child(main_scene.instantiate())
	await load_ready_now
	if NavMaster._map.scene_file_path == cur_map:
		EventBus.broadcast(EventBus.Event.new("LOAD_MAP", cur_map))
		await load_ready_now
	await NavMaster._map.load_map(save_file_folder+slot+'/')
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
	EventBus.broadcast(EventBus.Event.new("LOADED", "NULLDATA"))
	EventBus.broadcast(EventBus.Event.new("PRINT_LOG", "Loaded!"))
	loading = false

func load_ready(_map: GameMap)->void:
	load_ready_now.emit()

func parse_name(line: String)->String:
	return line.split("@SAVE_MARKER@")[1]
