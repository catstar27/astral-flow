extends Node2D

func _ready() -> void:
	GlobalRes.update_var(%GlobalTimer)
	GlobalRes.update_var(%SelectionCursor)
	load_map("res://maps/test_map.tscn")
	Dialogic.timeline_started.connect(enter_dialogue)
	Dialogic.timeline_ended.connect(exit_dialogue)

func unload_map()->void:
	if GlobalRes.map != null:
		GlobalRes.map.queue_free()
		GlobalRes.map = null

func load_map(map: String)->void:
	unload_map()
	var map_to_load: GameMap = load(map).instantiate()
	map_to_load.position = position
	add_child(map_to_load)
	GlobalRes.update_var(map_to_load)
	var player: Player = GlobalRes.player_scene.instantiate()
	player.position = map_to_load.map_to_local(map_to_load.player_start_pos)
	map_to_load.add_child(player)
	GlobalRes.update_var(player)
	GlobalRes.selection_cursor.position = map_to_load.map_to_local(map_to_load.player_start_pos)
	map_to_load.prep_map()

func enter_dialogue()->void:
	GlobalRes.selection_cursor.reset_move_dir()
	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
	GlobalRes.current_timeline.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func exit_dialogue()->void:
	get_tree().paused = false
	Dialogic.process_mode = Node.PROCESS_MODE_PAUSABLE
	GlobalRes.current_timeline.process_mode = Node.PROCESS_MODE_PAUSABLE
	GlobalRes.current_timeline = null
