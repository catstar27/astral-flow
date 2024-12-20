extends Node2D

@onready var global_timer: Timer = %GlobalTimer
@onready var combat_manager: CombatManager = %CombatManager
@onready var selection_cursor: SelectionCursor = %SelectionCursor
@onready var foreground: Sprite2D = %Foreground
var player: Player = null
var map: GameMap = null
var current_timeline: Node = null
var selection_cursor_scene: PackedScene = preload("res://misc/selection_cursor/selection_cursor.tscn")
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
	EventBus.subscribe("PAUSE", self, "pause")
	EventBus.subscribe("UNPAUSE", self, "unpause")
	EventBus.subscribe("VIDEO_SETTINGS_CHANGED", self, "set_video_settings")
	Dialogic.timeline_ended.connect(exit_dialogue)
	Dialogic.signal_event.connect(check_dialogue_signal)
	await get_tree().create_timer(.01).timeout
	load_map("res://maps/test_map.tscn")
	set_video_settings()

func _unhandled_input(event: InputEvent)->void:
	if event.is_action_pressed("quicksave"):
		SaveLoad.save_data()
	if event.is_action_pressed("quickload"):
		SaveLoad.load_data()

func set_video_settings()->void:
	if Settings.video.fullscreen:
		get_window().set_mode(Window.MODE_FULLSCREEN)
	else:
		get_window().set_mode(Window.MODE_WINDOWED)

func activate_selection_cursor()->void:
	selection_cursor.active = true

func deactivate_selection_cursor()->void:
	selection_cursor.active = false
	selection_cursor.deselect()

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

func pause()->void:
	selection_cursor.reset_move_dir()
	get_tree().paused = true

func unpause()->void:
	get_tree().paused = false

func enter_dialogue(info: Array)->void:
	current_timeline = Dialogic.start(info[0])
	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
	current_timeline.process_mode = Node.PROCESS_MODE_ALWAYS
	pause()

func exit_dialogue()->void:
	unpause()
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
	if data == "fade_out_exit":
		fade_out_exit()

func fade_out_exit()->void:
	deactivate_selection_cursor()
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, .5).set_ease(Tween.EASE_IN).finished
	await create_tween().tween_property(foreground, "modulate", Color(0,0,0,0), .5).set_ease(Tween.EASE_IN).finished
	await get_tree().create_timer(.5).timeout
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, .5).set_ease(Tween.EASE_IN).finished
	await create_tween().tween_property(foreground, "modulate", Color(0,0,0,0), .5).set_ease(Tween.EASE_IN).finished
	await get_tree().create_timer(.5).timeout
	EventBus.broadcast(EventBus.Event.new("FADE_MUSIC", 2))
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, 1).set_ease(Tween.EASE_IN).finished
	await get_tree().create_timer(1).timeout
	get_tree().quit()
