extends Node2D
class_name Main
## The game's main node; everything is a descendent of this.

@onready var global_timer: Timer = %GlobalTimer ## The global timer that determines in game time passage
@onready var gui: GUI = %GUI
@onready var selection_cursor: SelectionCursor = %SelectionCursor ## The selection cursor
@onready var foreground: Sprite2D = %Foreground ## Foreground for fade to black or shaders
@onready var sound_manager: SoundManager = %SoundManager ## Sound manager node
var num_paused: int = 0 ## Sources causing the game to be paused
var in_dialogue: bool = false ## Whether the game has dialogue running
var player: Player = null ## The player node
var map: GameMap = null ## The currently loaded map node
var current_timeline: Node = null ## Current dialogue timeline node
var player_scene: PackedScene = preload("uid://qjb7sn1qkk44") ## Preloaded player character
var text_indicator_scene: PackedScene = preload("uid://dtylaymiixbpw") ## Preloaded text indicators
var hour: int = 0 ## In game hour
var minute: int = 0 ## In game minute
var prepped: bool = false ## Whether this node has finished preparing
var last_map_name: String = "" ## Name of previously saved map
var to_save: Array[StringName] = [ ## Variables to save
	"hour",
	"minute",
	"last_map_name",
]
signal saved(node: Main) ## Emitted when this is saved
signal loaded(node: Main) ## Emitted when this is loaded

func _ready() -> void:
	if get_tree().paused:
		unpause()
	Engine.max_fps = maxi(roundi(DisplayServer.screen_get_refresh_rate()), 60)
	get_window().min_size = Vector2(960, 540)
	get_window().size_changed.connect(resize_elements)
	resize_elements()
	EventBus.subscribe("ENTER_DIALOGUE", self, "enter_dialogue")
	EventBus.subscribe("COMBAT_STARTED", global_timer, "stop")
	EventBus.subscribe("COMBAT_ENDED", global_timer, "start")
	EventBus.subscribe("MAKE_TEXT_INDICATOR", self, "create_text_indicator")
	EventBus.subscribe("LOAD_MAP", self, "load_map")
	EventBus.subscribe("LOAD_MAP_AT_ENTRANCE", self, "load_map_at_entrance")
	EventBus.subscribe("PAUSE", self, "pause")
	EventBus.subscribe("UNPAUSE", self, "unpause")
	EventBus.subscribe("VIDEO_SETTINGS_CHANGED", self, "set_video_settings")
	Dialogic.timeline_ended.connect(exit_dialogue)
	Dialogic.signal_event.connect(check_dialogue_signal)
	set_video_settings()
	if SaveLoad.is_slot_blank("save1"):
		EventBus.broadcast("QUEST_START", "AWAKENING")
		load_map("res://maps/test_map.tscn")
	else:
		SaveLoad.load_data("", "save1")
	prepped = true

## Resizes the gui when the screen resizes
func resize_elements()->void:
	gui.size = get_window().get_visible_rect().size

## Increments game time
func global_timer_timeout()->void:
	EventBus.broadcast("GLOBAL_TIMER_TIMEOUT", "NULLDATA")
	minute = (1+minute)%60
	if minute == 0:
		hour = (1+hour)%24
	EventBus.broadcast("TIME_CHANGED", [minute, hour])

## Pauses the game
func pause()->void:
	num_paused += 1
	selection_cursor.move_dir = Vector2.ZERO
	get_tree().paused = true

## Unpauses the game
func unpause()->void:
	num_paused -= 1
	if num_paused < 0:
		num_paused = 0
	if num_paused == 0:
		get_tree().paused = false

#region Dialogue
## Enters dialogue and pauses the game
func enter_dialogue(info: Array)->void:
	if in_dialogue:
		return
	EventBus.broadcast("DIALOGUE_ENTERED", "NULLDATA")
	in_dialogue = true
	current_timeline = Dialogic.start(info[0])
	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
	current_timeline.process_mode = Node.PROCESS_MODE_ALWAYS
	pause()

## Exits dialogue, unpausing the game
func exit_dialogue()->void:
	in_dialogue = false
	unpause()
	Dialogic.process_mode = Node.PROCESS_MODE_PAUSABLE
	current_timeline.process_mode = Node.PROCESS_MODE_PAUSABLE
	current_timeline = null
	EventBus.broadcast("DIALOGUE_EXITED", "NULLDATA")

## Performs various operations based on dialogic signals
func check_dialogue_signal(data)->void:
	if data is String:
		if data == "crash_game":
			queue_free()
		elif data == "fade_out_exit":
			selection_cursor.deactivate()
			await fade_out_slow()
			await get_tree().create_timer(.5).timeout
			get_tree().quit()
		elif data == "rest":
			await fade_out()
			EventBus.broadcast("REST", "NULLDATA")
			await get_tree().create_timer(.5).timeout
			await fade_in()
		elif data.left(12) == "start_quest:":
			EventBus.broadcast("QUEST_START", data.split("start_quest:")[1])
#endregion

#region Visuals
## Sets the window mode to match video settings
func set_video_settings()->void:
	if Settings.video.fullscreen:
		get_window().set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
	else:
		get_window().set_mode(Window.MODE_WINDOWED)

## Creates a text indicator with settings in the passed array
func create_text_indicator(info: Array)->void:
	var ind: TextIndicator = text_indicator_scene.instantiate()
	ind.hide()
	ind.text = info[0]
	ind.position = info[1]
	if info.size() == 3:
		ind.color = info[2]
	add_child(ind)
	ind.show()

## Fades the screen out slowly
func fade_out_slow()->void:
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, .5).set_ease(Tween.EASE_IN).finished
	await create_tween().tween_property(foreground, "modulate", Color(0,0,0,0), .5).set_ease(Tween.EASE_IN).finished
	await get_tree().create_timer(.5).timeout
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, .5).set_ease(Tween.EASE_IN).finished
	await create_tween().tween_property(foreground, "modulate", Color(0,0,0,0), .5).set_ease(Tween.EASE_IN).finished
	await get_tree().create_timer(.5).timeout
	EventBus.broadcast("FADE_OUT_MUSIC", 1)
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, 1).set_ease(Tween.EASE_IN).finished

## Fades the screen out
func fade_out()->void:
	EventBus.broadcast("FADE_OUT_MUSIC", 1)
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, 1).set_ease(Tween.EASE_IN).finished

## Fades the screen in
func fade_in()->void:
	EventBus.broadcast("FADE_IN_MUSIC", 1)
	await create_tween().tween_property(foreground, "modulate", Color(0,0,0,0), .5).set_ease(Tween.EASE_OUT).finished

## Fades to black over custom time
func custom_fade_out(duration: float)->void:
	await create_tween().tween_property(foreground, "modulate", Color.BLACK, duration).set_ease(Tween.EASE_IN).finished

## Fades in over custom time
func custom_fade_in(duration: float)->void:
	await create_tween().tween_property(foreground, "modulate", Color(0,0,0,0), duration).set_ease(Tween.EASE_OUT).finished
#endregion

#region Save and Load
## Helper that allows running load_map with an entrance id from an Event
func load_map_at_entrance(args: Array)->void:
	if args.size() != 2 || args[0] is not String || args[1] is not String:
		printerr("Invalid arguments for loading map at entrance")
		return
	load_map(args[0], args[1])

## Loads a map from the given filepath. Optionally places the player in a location based on the entrance used.
func load_map(new_map: String, entrance_id: String = "")->void:
	gui.hide()
	await custom_fade_out(.5)
	selection_cursor.hide()
	if player != null && player.in_combat:
		%CombatManager.end_combat()
	await unload_map()
	selection_cursor.deactivate()
	var map_to_load: GameMap = load(new_map).instantiate()
	map_to_load.position = position
	add_child(map_to_load)
	NavMaster.map = map_to_load
	map = map_to_load
	map.process_mode = Node.PROCESS_MODE_PAUSABLE
	SaveLoad.load_map(map_to_load)
	while !map_to_load.is_node_ready():
		await map_to_load.ready
	if player == null:
		player = player_scene.instantiate()
		player.name = "Kalin"
	else:
		remove_child(player)
	map_to_load.add_child(player)
	var player_pos: Vector2
	var entrance: TravelPoint = map_to_load.get_entrance(entrance_id)
	if last_map_name == map_to_load.name:
		player_pos = map_to_load.last_player_pos[player.name]
	elif entrance == null:
		player_pos = map_to_load.map_to_local(map_to_load.player_start_pos)
	else:
		player_pos = entrance.get_exit_position()
	player.position = map_to_load.map_to_local(map_to_load.local_to_map(player_pos))
	SaveLoad.load_player(player)
	while selection_cursor.moving:
		await selection_cursor.move_stopped
	selection_cursor.position = player.position
	selection_cursor.activate()
	selection_cursor.select(player)
	map_to_load.prep_map()
	SaveLoad.save_data("Autosave", SaveLoad.recent_slot, true)
	if sound_manager.ost.stream != map_to_load.calm_theme:
		EventBus.broadcast("SET_OST", map_to_load.calm_theme)
	EventBus.broadcast("MAP_ENTERED", map_to_load.map_name)
	selection_cursor.show()
	await custom_fade_in(.5)
	gui.show()

## Unloads the current map after saving it
func unload_map()->void:
	if map != null:
		last_map_name = map.name
		SaveLoad.save_map(map)
		selection_cursor.deselect()
		if player != null:
			map.remove_child(player)
			add_child(player)
		map.queue_free()
		while is_instance_valid(map):
			await get_tree().process_frame
		map = null

## Executes before making the save dict
func pre_save()->void:
	last_map_name = map.name

## Executes after making the save dict
func post_save()->void:
	saved.emit(self)

## Executes before loading data
func pre_load()->void:
	return

## Executes after loading data
func post_load()->void:
	EventBus.broadcast("TIME_CHANGED", [minute, hour])
	loaded.emit(self)
#endregion
