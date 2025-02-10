extends Node2D

@onready var global_timer: Timer = %GlobalTimer
@onready var selection_cursor: SelectionCursor = %SelectionCursor
@onready var foreground: Sprite2D = %Foreground
@onready var sound_manager: SoundManager = %SoundManager
var in_dialogue: bool = false
var player: Player = null
var map: GameMap = null
var current_timeline: Node = null
var selection_cursor_scene: PackedScene = preload("res://misc/selection_cursor/selection_cursor.tscn")
var player_scene: PackedScene = preload("res://characters/player.tscn")
var text_indicator_scene: PackedScene = preload("res://misc/hud/text_indicator.tscn")
var hour: int = 0
var minute: int = 0
var prepped: bool = false

func _ready() -> void:
	if get_tree().paused:
		unpause()
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
	set_video_settings()
	if SaveLoad.is_slot_blank("save1"):
		load_map("res://maps/test_map.tscn")
	else:
		SaveLoad.load_data()
	prepped = true

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
	EventBus.broadcast("ACTIVATE_SELECTION", "NULLDATA")

func deactivate_selection_cursor()->void:
	EventBus.broadcast("DEACTIVATE_SELECTION", "NULLDATA")
	selection_cursor.deselect()

func global_timer_timeout()->void:
	EventBus.broadcast("GLOBAL_TIMER_TIMEOUT", "NULLDATA")
	minute = (1+minute)%60
	if minute == 0:
		hour = (1+hour)%24
	EventBus.broadcast("TIME_CHANGED", [minute, hour])

func unload_map()->void:
	if map != null:
		await SaveLoad.save_data(true)
		if player != null:
			map.remove_child(player)
			add_child(player)
		map.unload()
		map = null

func load_map(new_map: String)->void:
	await unload_map()
	await get_tree().create_timer(.01).timeout
	var map_to_load: GameMap = load(new_map).instantiate()
	map_to_load.position = position
	add_child(map_to_load)
	map = map_to_load
	map.process_mode = Node.PROCESS_MODE_PAUSABLE
	if player == null:
		player = player_scene.instantiate()
	else:
		remove_child(player)
	map_to_load.add_child(player)
	player.position = map_to_load.map_to_local(map_to_load.player_start_pos)
	if map_to_load.has_save_data():
		map_to_load.prep_map()
		await SaveLoad.load_map(map_to_load)
	map_to_load.prep_map()
	if selection_cursor.last_map_name != map.map_name:
		selection_cursor.position = player.position
	await SaveLoad.save_data(true)
	if sound_manager.ost.stream != map_to_load.ost:
		EventBus.broadcast("SET_OST", map_to_load.ost)
	EventBus.broadcast("MAP_ENTERED", map_to_load.map_name)

func pause()->void:
	selection_cursor.reset_move_dir()
	get_tree().paused = true

func unpause()->void:
	get_tree().paused = false

func enter_dialogue(info: Array)->void:
	if in_dialogue:
		return
	in_dialogue = true
	current_timeline = Dialogic.start(info[0])
	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
	current_timeline.process_mode = Node.PROCESS_MODE_ALWAYS
	pause()

func exit_dialogue()->void:
	in_dialogue = false
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
	elif data == "fade_out_exit":
		deactivate_selection_cursor()
		await fade_out()
		await get_tree().create_timer(.5).timeout
		get_tree().quit()
	elif data == "rest":
		await fade_out()
		EventBus.broadcast("REST", "NULLDATA")
		await get_tree().create_timer(.5).timeout
		EventBus.broadcast("FADE_IN_MUSIC", 1)
		await fade_in()

func fade_out()->void:
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, .5).set_ease(Tween.EASE_IN).finished
	await create_tween().tween_property(foreground, "modulate", Color(0,0,0,0), .5).set_ease(Tween.EASE_IN).finished
	await get_tree().create_timer(.5).timeout
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, .5).set_ease(Tween.EASE_IN).finished
	await create_tween().tween_property(foreground, "modulate", Color(0,0,0,0), .5).set_ease(Tween.EASE_IN).finished
	await get_tree().create_timer(.5).timeout
	EventBus.broadcast("FADE_OUT_MUSIC", 1)
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, 1).set_ease(Tween.EASE_IN).finished

func fade_in()->void:
	await create_tween().tween_property(foreground, "modulate", Color(0,0,0,0), 1).set_ease(Tween.EASE_IN).finished

func save_data(file: FileAccess)->void:
	file.store_var(hour)
	file.store_var(minute)

func load_data(file: FileAccess)->void:
	hour = file.get_var()
	minute = file.get_var()
	EventBus.broadcast("TIME_CHANGED", [minute, hour])
