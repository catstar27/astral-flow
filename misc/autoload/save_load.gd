extends Node

var slot: String = "Save1"
var save_file_folder: String = "user://saves/"
var main_scene: PackedScene = preload("res://misc/main.tscn")
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

func save_data()->void:
	if !DirAccess.dir_exists_absolute(save_file_folder):
		DirAccess.make_dir_absolute(save_file_folder)
	var file: FileAccess = FileAccess.open(save_file_folder+slot, FileAccess.WRITE)
	for node in get_tree().get_nodes_in_group("Persist"):
		if !node.has_method("save_data"):
			printerr("Persistent node"+node.name+"missing save data function")
		file.store_var("@SAVE_MARKER@"+node.name+"@SAVE_MARKER@")
		await node.save_data(file)
	file.store_var("DIALOGIC_VARS")
	for variable in Dialogic.VAR.variables():
		file.store_var(Dialogic.VAR.get_variable(variable))
	file.store_var("END_OF_SAVE_DATA")
	EventBus.broadcast(EventBus.Event.new("PRINT_LOG", "Quicksaved!"))

func load_data()->void:
	var file: FileAccess = FileAccess.open(save_file_folder+slot, FileAccess.READ)
	EventBus.subscribe("MAP_LOADED", self, "load_ready")
	EventBus.broadcast(EventBus.Event.new("DELOAD", "NULLDATA"))
	await get_tree().create_timer(.01).timeout
	get_tree().root.add_child(main_scene.instantiate())
	await load_ready_now
	EventBus.remove_subscriber(self)
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
	EventBus.broadcast(EventBus.Event.new("LOADED", "NULLDATA"))
	EventBus.broadcast(EventBus.Event.new("PRINT_LOG", "Quickloaded!"))

func load_ready(_map: GameMap)->void:
	load_ready_now.emit()

func parse_name(line: String)->String:
	return line.split("@SAVE_MARKER@")[1]
