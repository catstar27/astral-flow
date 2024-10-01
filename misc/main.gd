extends Node2D

func _ready() -> void:
	GlobalRes.player = %Player
	GlobalRes.selection_cursor = %SelectionCursor
	load_map("res://maps/test_map.tscn")

func unload_map()->void:
	if GlobalRes.map != null:
		GlobalRes.map.queue_free()

func load_map(map: String)->void:
	unload_map()
	var map_to_load: GameMap = load(map).instantiate()
	map_to_load.position = position
	add_child(map_to_load)
	GlobalRes.map = map_to_load
	GlobalRes.player.position = map_to_load.map_to_local(map_to_load.player_start_pos)
	GlobalRes.selection_cursor.position = map_to_load.map_to_local(map_to_load.cursor_start_pos)
