extends Node2D
class_name Main
## The game's main node; everything is a descendent of this.

@onready var global_timer: Timer = %GlobalTimer ## The global timer that determines in game time passage
@onready var selection_cursor: SelectionCursor = %SelectionCursor ## The selection cursor
@onready var foreground: Sprite2D = %Foreground ## Foreground for fade to black or shaders
@onready var sound_manager: SoundManager = %SoundManager ## Sound manager node
var in_dialogue: bool = false ## Whether the game has dialogue running
var player: Player = null ## The player node
var map: GameMap = null ## The currently loaded map node
var current_timeline: Node = null ## Current dialogue timeline node
var player_scene: PackedScene = preload("res://characters/generic/player.tscn") ## Preloaded player character
var text_indicator_scene: PackedScene = preload("res://misc/hud/text_indicator.tscn") ## Preloaded text indicators
var hour: int = 0 ## In game hour
var minute: int = 0 ## In game minute
var prepped: bool = false ## Whether this node has finished preparing
var to_save: Array[StringName] = [ ## Variables to save
	"hour",
	"minute",
]
signal saved(node: Main) ## Emitted when this is saved
signal loaded(node: Main) ## Emitted when this is loaded

func _ready() -> void:
	if get_tree().paused:
		unpause()
	get_window().min_size = Vector2(960, 540)
	EventBus.subscribe("ENTER_DIALOGUE", self, "enter_dialogue")
	EventBus.subscribe("COMBAT_STARTED", global_timer, "stop")
	EventBus.subscribe("COMBAT_ENDED", global_timer, "start")
	EventBus.subscribe("MAKE_TEXT_INDICATOR", self, "create_text_indicator")
	EventBus.subscribe("LOAD_MAP", self, "load_map")
	EventBus.subscribe("LOAD_MAP_AT_ENTRANCE", self, "load_map_at_entrance")
	EventBus.subscribe("DELOAD", self, "queue_free")
	EventBus.subscribe("PAUSE", self, "pause")
	EventBus.subscribe("UNPAUSE", self, "unpause")
	EventBus.subscribe("VIDEO_SETTINGS_CHANGED", self, "set_video_settings")
	Dialogic.timeline_ended.connect(exit_dialogue)
	Dialogic.signal_event.connect(check_dialogue_signal)
	set_video_settings()
	if SaveLoad.is_slot_blank("save1"):
		load_map("res://maps/test_map.tscn")
		EventBus.broadcast("QUEST_START", "AWAKENING")
	else:
		SaveLoad.load_data()
	prepped = true

## Increments game time
func global_timer_timeout()->void:
	EventBus.broadcast("GLOBAL_TIMER_TIMEOUT", "NULLDATA")
	minute = (1+minute)%60
	if minute == 0:
		hour = (1+hour)%24
	EventBus.broadcast("TIME_CHANGED", [minute, hour])

## Pauses the game
func pause()->void:
	selection_cursor.move_dir = Vector2.ZERO
	get_tree().paused = true

## Unpauses the game
func unpause()->void:
	get_tree().paused = false

#region Dialogue
## Enters dialogue and pauses the game
func enter_dialogue(info: Array)->void:
	if in_dialogue:
		return
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
	await create_tween().tween_property(foreground, "modulate", Color(0,0,0,0), 1).set_ease(Tween.EASE_IN).finished
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
	await unload_map()
	selection_cursor.deactivate()
	var map_to_load: GameMap = load(new_map).instantiate()
	map_to_load.position = position
	add_child(map_to_load)
	NavMaster.map = map_to_load
	map = map_to_load
	map.process_mode = Node.PROCESS_MODE_PAUSABLE
	var new_player: bool = false
	if player == null:
		player = player_scene.instantiate()
		new_player = true
	else:
		remove_child(player)
	map_to_load.add_child(player)
	if map_to_load.has_save_data():
		await SaveLoad.load_map(map_to_load)
	var entrance: TravelPoint = map_to_load.get_entrance(entrance_id)
	if entrance == null:
		player.position = map_to_load.map_to_local(map_to_load.player_start_pos)
	else:
		player.position = entrance.get_exit_position()
	map_to_load.prep_map()
	if new_player:
		SaveLoad.load_player(player)
	while selection_cursor.moving:
		await selection_cursor.move_stopped
	selection_cursor.position = player.position
	selection_cursor.activate()
	await SaveLoad.save_data(true)
	if sound_manager.ost.stream != map_to_load.calm_theme:
		EventBus.broadcast("SET_OST", map_to_load.calm_theme)
	EventBus.broadcast("MAP_ENTERED", map_to_load.map_name)

## Unloads the current map after saving it
func unload_map()->void:
	if map != null:
		await SaveLoad.save_data(true)
		if player != null:
			map.remove_child(player)
			add_child(player)
		map.queue_free()
		map = null
		await get_tree().create_timer(.01).timeout

## Saves the main node's data
func save_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.WRITE)
	for var_name in to_save:
		file.store_var(var_name)
		file.store_var(get(var_name))
	file.store_var("END")
	file.close()
	saved.emit(self)

## Loads the main node's data
func load_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.READ)
	var var_name: String = file.get_var()
	while var_name != "END":
		set(var_name, file.get_var())
		var_name = file.get_var()
	file.close()
	EventBus.broadcast("TIME_CHANGED", [minute, hour])
	loaded.emit(self)
#endregion
