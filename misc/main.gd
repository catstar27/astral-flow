extends Node2D

@onready var global_timer: Timer = %GlobalTimer
@onready var combat_manager: CombatManager = %CombatManager
@onready var selection_cursor: SelectionCursor = %SelectionCursor
var map: GameMap = null
var current_timeline: Node = null
var selection_cursor_scene: PackedScene = preload("res://misc/selection_cursor.tscn")
var player_scene: PackedScene = preload("res://characters/player.tscn")
var text_indicator_scene: PackedScene = preload("res://misc/hud/text_indicator.tscn")

func _ready() -> void:
	get_window().min_size = Vector2(960, 540)
	EventBus.subscribe("ENTER_DIALOGUE", self, "enter_dialogue")
	EventBus.subscribe("COMBAT_STARTED", global_timer, "stop")
	EventBus.subscribe("COMBAT_ENDED", global_timer, "start")
	EventBus.subscribe("MAKE_TEXT_INDICATOR", self, "create_text_indicator")
	Dialogic.timeline_ended.connect(exit_dialogue)
	load_map("res://maps/test_map.tscn")

func global_timer_timeout()->void:
	EventBus.broadcast(EventBus.Event.new("GLOBAL_TIMER_TIMEOUT", "NULLDATA"))

func unload_map()->void:
	if map != null:
		map.queue_free()
		map = null

func load_map(new_map: String)->void:
	unload_map()
	var map_to_load: GameMap = load(new_map).instantiate()
	map_to_load.position = position
	add_child(map_to_load)
	map = map_to_load
	var player: Player = player_scene.instantiate()
	player.position = map_to_load.map_to_local(map_to_load.player_start_pos)
	map_to_load.add_child(player)
	selection_cursor.position = map_to_load.map_to_local(map_to_load.player_start_pos)
	map_to_load.prep_map()
	EventBus.broadcast(EventBus.Event.new("MAP_LOADED", map))

func enter_dialogue(info: Array)->void:
	selection_cursor.reset_move_dir()
	current_timeline = Dialogic.start(info[0])
	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
	current_timeline.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

func exit_dialogue()->void:
	get_tree().paused = false
	Dialogic.process_mode = Node.PROCESS_MODE_PAUSABLE
	current_timeline.process_mode = Node.PROCESS_MODE_PAUSABLE
	current_timeline = null

func create_text_indicator(info: Array)->void:
	var ind: TextIndicator = text_indicator_scene.instantiate()
	ind.text = info[0]
	ind.position = info[1]
	if info.size() == 3:
		ind.color = info[2]
	add_child(ind)
