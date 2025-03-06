extends CharacterBody2D
class_name Character
## Base class for characters that move and interact with the environment and other characters

#region Stats
@export var star_stats: Dictionary[String, int] = { ## Stats on the stat star
	"intelligence": 10,
	"agility": 10,
	"strength": 10,
	"endurance": 10,
	"charisma": 10,
	"resolve": 10,
	"passion": 10
}
var base_stats: Dictionary[String, int] = { ## Base stats calculated from star stats
	"max_ap": 0,
	"max_mp": 0,
	"max_hp": 0,
	"avoidance": 0,
	"crit_range": 1,
	"defense": 0,
	"damage_threshold": 10,
	"sequence": 0
}
var stat_mods: Dictionary[String, int] = { ## Stat modifiers from statuses, etc.
	"max_ap": 0,
	"max_mp": 0,
	"max_hp": 0,
	"avoidance": 0,
	"crit_range": 0,
	"defense": 0,
	"damage_threshold": 0,
	"sequence": 0
}
#endregion
#region Exports
@export var allies: Array[Character] = [] ## List of allies to bring into combat alongside this character
@export var export_abilities: Array[Ability] = [] ## Exported ability list for initial abilities
@export var display_name: String = "Name Here" ## Name displayed in gui and logs
@export var text_indicator_shift: Vector2 = Vector2.UP*32 ## Distance away from this to spawn text indicators
@export_group("Schedule") ## Exports related to this character's schedule. Do not use for the player
@export var use_timed_schedule: bool ## Whether the schedule changes based on in game time
@export var schedule: Array[NPCTask] ## List of tasks for the character to carry out
@export var loop_schedule: bool = false ## Whether the schedule repeats when reaching the end
@export var task_blocked_dialogue: DialogicTimeline ## Dialogue to trigger when a task is blocked from completion
@export_group("Activation") ## Exports related to character's active state
@export var active: bool = true ## Whether the character is active in the game map or disabled
#endregion
#region Vars
@onready var sprite: Sprite2D = %Sprite
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var state_machine: StateMachine = %StateMachine
@onready var status_manager: StatusManager = %StatusManager
@onready var range_indicator_scene: PackedScene = preload("res://misc/selection_cursor/range_indicator.tscn")
var abilities: Array[Ability] = [] ## Actual list of abilities
var sequence: int ## Order of this character in the current combat and turn
var in_combat: bool = false ## Whether this character is in combat
var taking_turn: bool = false ## Whether this character is taking their turn
var range_indicators: Array[Sprite2D] = [] ## Range indicators for selected ability
var selected_ability: Ability = null ## Ability attempted to be used by the character
var cur_ap: int ## Character's current action points
var cur_mp: int ## Character's current health points
var cur_hp: int ## Character's current magic points
var schedule_index: int = 0 ## Current index of the task being executed
var schedule_executed: bool = false ## Whether the schedule has been fully executed
var schedule_processing: bool = false ## Whether the schedule is being executed currently
var is_selected: bool = false ## Whether this character is selected
var to_save: Array[StringName] = [ ## Variables to save
	"position",
	"star_stats",
	"base_stats",
	"ability_scenes",
	"cur_hp",
	"cur_ap",
	"cur_mp",
	"active",
	"schedule_executed",
	"schedule_index"
]
#endregion
#region Signals
signal move_order(pos: Vector2) ## Emitted when the character attempts to move
signal stop_move_order ## Emitted to halt character movement
signal interact_order(target: Node2D) ## Emitted when character tries interacting
signal ability_order(ability: Ability, destination: Vector2) ## Emitted when character tries using ability
signal pos_changed(character: Character) ## Emitted when the character's position changes
signal ended_turn(character: Character) ## Emitted when the character's turn ends
signal stats_changed ## Emitted when the character's stats change
signal abilities_changed ## Emitted when the character's abilities change
signal defeated(character: Character) ## Emitted upon defeat; Sends the character defeated
signal defeated_at(pos: Vector2) ## Emitted upon defeat; Sends the character defeated position
signal defeated_named(display_name: String) ## Emitted upon defeat; Sends the character defeated name
signal damaged(source: Node) ## Emitted upon taking damage; Sends the damage source
signal rested ## Emitted when the character rests
signal combat_entered ## Emitted when the character enters combat
signal combat_exited ## Emitted when the character exits combat
signal ability_deselected ## Emitted when the character deselects their ability
signal saved(node: Character) ## Emitted when the character saves data
signal loaded(node: Character) ## Emitted when the character loads data
#endregion

#region Prep
func _ready() -> void:
	_setup()

## Called alongside _ready to setup the character
func _setup()->void:
	if !active:
		hide()
	EventBus.subscribe("GLOBAL_TIMER_TIMEOUT", self, "refresh")
	EventBus.subscribe("REST", self, "rest")
	status_manager.status_damage_ticked.connect(damage)
	status_manager.status_stat_mod_changed.connect(update_stat_mod)
	status_manager.status_action_occurred.connect(process_status_action)
	pos_changed.connect(status_manager.process_move)
	rested.connect(status_manager.process_rest)
	damaged.connect(status_manager.process_damage)
	damaged.connect(on_damaged)
	duplicate_export_abilities()
	calc_base_stats()
	cur_hp = base_stats.max_hp+stat_mods.max_hp
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	cur_mp = base_stats.max_mp+stat_mods.max_mp
	set_outline_color()
	EventBus.subscribe("GAMEPLAY_SETTINGS_CHANGED", self, "set_outline_color")
	init_schedule()

## Duplicates the export abilities, copying them into the actual ability array
func duplicate_export_abilities()->void:
	for ability in export_abilities:
		var copy: Ability = ability.duplicate_ability()
		copy.user = self
		abilities.append(copy)

## Calculates base stats based on star stats
func calc_base_stats()->void:
	base_stats.max_hp = maxi(5+(star_stats.endurance-10)*2+(star_stats.strength-10), 5)
	base_stats.max_ap = maxi(2+(star_stats.agility-10)+(star_stats.resolve-10), 5)
	base_stats.max_mp = maxi(5+(star_stats.intelligence-10)+(star_stats.passion-10), 5)
	base_stats.avoidance = maxi(10+(star_stats.agility-10)*2+(star_stats.charisma-10), 0)
	base_stats.sequence = (star_stats.passion-10)+(star_stats.agility-10)

## Updates stat modifiers based on given args
func update_stat_mod(stat_mod_name: String, amount: int)->void:
	if stat_mod_name not in stat_mods:
		printerr("Attempted to change stat mod "+stat_mod_name+" not in stat_mods")
	else:
		stat_mods[stat_mod_name] += amount

## Refreshes the character; called either when a combat round starts or time ticks
func refresh()->void:
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	stats_changed.emit()
	status_manager.tick_status()

## Rests the character, replenishing magic and health as well as action points
func rest()->void:
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	cur_hp = base_stats.max_hp+stat_mods.max_hp
	cur_mp = base_stats.max_mp+stat_mods.max_mp
	rested.emit()
#endregion

#region Tasks
## Initializes the schedule by setting the user of all tasks
func init_schedule()->void:
	for task in schedule:
		task.user = self

## Processes the schedule, running the proper task
func process_schedule()->void:
	if schedule.size() == 0 || in_combat || !active:
		return
	if !loop_schedule && schedule_executed:
		return
	if !use_timed_schedule:
		schedule_processing = true
		schedule[schedule_index].task_completed.connect(task_done)
		schedule[schedule_index].call_deferred("execute_task")

## Called when the current task has been executed to determine the next action to take
func task_done()->void:
	schedule[schedule_index].task_completed.disconnect(task_done)
	schedule_processing = false
	schedule_index = (schedule_index+1)%schedule.size()
	if (schedule_index == 0 && !loop_schedule) || !active:
		if schedule_index == 0:
			schedule_executed = true
		return
	process_schedule()
#endregion

#region Orders
## Attempts to start moving the character
func move(pos: Vector2)->void:
	move_order.emit(pos)

## Attempts to stop the character from moving
func stop_movement()->void:
	stop_move_order.emit()

## Attempts to interact with a target
func interact(target: Node2D)->void:
	interact_order.emit(target)

## Attempts to activate an ability at a destination
func activate_ability(ability: Ability, destination: Vector2)->void:
	ability_order.emit(ability, destination)
#endregion

#region Combat
## Called when the character enters combat
func enter_combat()->void:
	in_combat = true
	combat_entered.emit()

## Called when the character exits combat
func exit_combat()->void:
	in_combat = false
	combat_exited.emit()
	process_schedule()

## Rolls the character's current sequence, adding randomness to the turn order
func roll_sequence()->void:
	sequence = base_stats.sequence+stat_mods.sequence+randi_range(1,10)

## Called upon defeat; also deactivates the character
func on_defeated()->void:
	EventBus.broadcast("PRINT_LOG","Defeated "+display_name)
	EventBus.broadcast("TILE_UNOCCUPIED", position)
	if taking_turn:
		ended_turn.emit(self)
	defeated.emit(self)
	defeated_at.emit(position)
	defeated_named.emit(display_name)
	deactivate()

## Damages the character for a given amount
func damage(source: Node, amount: int, _damage_type: Ability.damage_type_options, ignore_defense: bool = false)->void:
	var text_ind_pos: Vector2 = text_indicator_shift+global_position
	if amount >= base_stats.damage_threshold+stat_mods.damage_threshold || ignore_defense:
		cur_hp -= amount
		EventBus.broadcast("MAKE_TEXT_INDICATOR", [str(-amount), text_ind_pos])
	else:
		var damage_reduced: int = maxi(amount-base_stats.defense-stat_mods.defense, 0)
		cur_hp -= damage_reduced
		if damage_reduced > 0:
			EventBus.broadcast("MAKE_TEXT_INDICATOR", [str(-damage_reduced), text_ind_pos])
		else:
			EventBus.broadcast("MAKE_TEXT_INDICATOR", ["Blocked!", text_ind_pos])
	damaged.emit(source)
	stats_changed.emit()
	if cur_hp <= 0:
		anim_player.play("Character/defeat")

## Waits until the character is idle, then ends their turn
func end_turn()->void:
	while state_machine.current_state.state_id != "IDLE":
		await state_machine.state_changed
	remove_range_indicators()
	ended_turn.emit(self)
#endregion

#region Abilities
## Selects the given ability and places its indicators
func select_ability(ability: Ability)->void:
	while state_machine.current_state.state_id == "MOVE":
		await state_machine.state_changed
	selected_ability = ability
	place_range_indicators(ability)

## Deselects the given ability and removes its indicators
func deselect_ability(will_reselect: bool = false)->void:
	selected_ability = null
	remove_range_indicators()
	if !will_reselect:
		ability_deselected.emit()

## Adds an ability
func add_ability(ability: Ability)->void:
	abilities.append(ability)
	ability.user = self
	abilities_changed.emit()

## Places indicators showing range for a given ability
func place_range_indicators(ability: Ability)->void:
	for location in ability.get_valid_destinations():
		var indicator: Sprite2D = range_indicator_scene.instantiate()
		indicator.modulate = ability.get_targeting_color()
		indicator.position = location-position
		add_child(indicator)
		range_indicators.append(indicator)

## Removes all indicators
func remove_range_indicators()->void:
	while range_indicators.size()>0:
		range_indicators.pop_front().queue_free()
#endregion

#region Status
## Adds the given status to this character
func add_status(status: Status, source: Node)->void:
	status_manager.add_status(status, source)
	var info: Array = [status.display_name, text_indicator_shift+global_position, status.status_color]
	EventBus.broadcast("MAKE_TEXT_INDICATOR", info)

## Processes a status action, running the function with the given args
func process_status_action(action: Callable, args: Array)->void:
	deselect_ability()
	var prev_pos: Vector2 = position
	await action.call(args)
	if position != prev_pos:
		pos_changed.emit(self)
#endregion

#region Misc
## Sets the color of the character's outline
func set_outline_color()->void:
	var color: Color = Color(Settings.gameplay.selection_tint, 180.0/255.0)
	sprite.material.set_shader_parameter("outline_color", color)

## Selects the character and adds the outline
func select()->void:
	sprite.material.set_shader_parameter("width", 1)
	is_selected = true

## Deselects the character and removes the outline
func deselect()->void:
	sprite.material.set_shader_parameter("width", 0)
	if has_method("deselect_ability"):
		call("deselect_ability")
	is_selected = false

## Activates the character, putting them into the game map at given position
func activate(pos: Vector2)->void:
	active = true
	position = pos
	EventBus.broadcast("TILE_OCCUPIED", pos)
	show()
	if !schedule_processing:
		process_schedule()

## Deactivates the character
func deactivate()->void:
	active = false
	EventBus.broadcast("TILE_UNOCCUPIED", position)
	hide()

## Called when the character is damaged
func on_damaged(_source: Node)->void:
	return
#endregion

#region Saving and Loading
## Saves the character's data
func save_data(dir: String)->void:
	stop_move_order.emit()
	if active && schedule != []:
		schedule[schedule_index].pause.emit()
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.WRITE)
	for var_name in to_save:
		file.store_var(var_name)
		file.store_var(get(var_name))
	file.store_var("END")
	file.close()
	if active && schedule != []:
		schedule[schedule_index].unpause.emit()
	saved.emit(self)

## Loads the character's data and resets position to be centered to the tile
func load_data(dir: String)->void:
	deselect()
	state_machine.pause()
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.READ)
	if file != null:
		var var_name: String = file.get_var()
		while var_name != "END":
			set(var_name, file.get_var())
			var_name = file.get_var()
		file.close()
	position = NavMaster.map.map_to_local(NavMaster.map.local_to_map(position))
	load_extra()
	state_machine.unpause()
	if active:
		activate(position)
	else:
		deactivate()
	loaded.emit(self)

## Contains extra protocol in child classes for after loading is complete
func load_extra()->void:
	return
#endregion
