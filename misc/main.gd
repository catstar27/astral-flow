extends Node2D

@onready var global_timer: Timer = %GlobalTimer
@onready var combat_manager: CombatManager = %CombatManager
@onready var selection_cursor: SelectionCursor = %SelectionCursor
var player: Player = null
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
	EventBus.subscribe("LOAD_MAP", self, "load_map")
	EventBus.subscribe("DELOAD", self, "queue_free")
	Dialogic.timeline_ended.connect(exit_dialogue)
	Dialogic.signal_event.connect(check_dialogue_signal)
	await get_tree().create_timer(.01).timeout
	load_map("res://maps/test_map.tscn")

func _unhandled_input(event: InputEvent)->void:
	if event.is_action_pressed("quicksave"):
		SaveLoad.save_data()
	if event.is_action_pressed("quickload"):
		SaveLoad.load_data()

func global_timer_timeout()->void:
	EventBus.broadcast(EventBus.Event.new("GLOBAL_TIMER_TIMEOUT", "NULLDATA"))

func unload_map()->void:
	if map != null:
		if player != null:
			map.remove_child(player)
			add_child(player)
		map.unload()
		map = null

func load_map(new_map: String)->void:
	unload_map()
	await get_tree().create_timer(.01).timeout
	var map_to_load: GameMap = load(new_map).instantiate()
	map_to_load.position = position
	add_child(map_to_load)
	map = map_to_load
	if player == null:
		player = player_scene.instantiate()
	else:
		remove_child(player)
	map_to_load.add_child(player)
	player.position = map_to_load.map_to_local(map_to_load.player_start_pos)
	selection_cursor.position = map_to_load.map_to_local(map_to_load.player_start_pos)
	map_to_load.prep_map()

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
	ind.global_position = info[1]
	if info.size() == 3:
		ind.color = info[2]
	add_child(ind)

func check_dialogue_signal(data)->void:
	if data == "crash_game":
		queue_free()
