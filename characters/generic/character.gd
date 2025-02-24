extends CharacterBody2D
class_name Character

#region Stats
@export var star_stats: Dictionary = {
	"intelligence": 10,
	"agility": 10,
	"strength": 10,
	"endurance": 10,
	"charisma": 10,
	"resolve": 10,
	"passion": 10
}
var base_stats: Dictionary = {
	"max_ap": 0,
	"max_mp": 0,
	"max_hp": 0,
	"avoidance": 0,
	"crit_range": 1,
	"defense": 0,
	"damage_threshold": 10,
	"sequence": 0
}
var stat_mods: Dictionary = {
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
@export var allies: Array[Character] = []
@export var ability_scenes: Array[String] = []
@export var display_name: String = "Name Here"
@export var text_indicator_shift: Vector2 = Vector2.UP*32
@export_group("Schedule")
@export var use_timed_schedule: bool
@export var schedule: Array[NPCTask]
@export var loop_schedule: bool = false
@export var task_blocked_dialogue: DialogicTimeline
@export_group("Activation")
@export var active: bool = true
#endregion
@onready var sprite: Sprite2D = %Sprite
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var state_machine: StateMachine = %StateMachine
@onready var status_manager: StatusManager = %StatusManager
@onready var range_indicator_scene: PackedScene = preload("res://misc/selection_cursor/range_indicator.tscn")
var sequence: int
var in_combat: bool = false
var taking_turn: bool = false
var range_indicators: Array[Sprite2D] = []
var selected_ability: Ability = null
var cur_ap: int
var cur_mp: int
var cur_hp: int
var target_position: Vector2 = position
var schedule_index: int = 0
var schedule_executed: bool = false
#region Save Vars Array
var to_save: Array[StringName] = [
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
@warning_ignore("unused_signal") signal move_order(pos: Vector2)
@warning_ignore("unused_signal") signal stop_move_order
@warning_ignore("unused_signal") signal interact_order(object: Node2D)
@warning_ignore("unused_signal") signal ability_order(data: Array)
signal pos_changed(character: Character)
signal anim_activate_ability
signal ended_turn(character: Character)
signal stats_changed
signal abilities_changed
signal defeated(character: Character)
signal defeated_at(pos: Vector2)
signal defeated_named(display_name: String)
signal damaged
signal combat_entered
signal combat_exited
signal ability_deselected
signal saved(node)
signal loaded(node)
#endregion

#region Prep
func _setup()->void:
	if !active:
		hide()
	EventBus.subscribe("GLOBAL_TIMER_TIMEOUT", self, "refresh")
	EventBus.subscribe("REST", self, "rest")
	status_manager.status_damage_ticked.connect(damage)
	status_manager.status_stat_mod_changed.connect(update_stat_mod)
	status_manager.status_action_occurred.connect(process_status_action)
	damaged.connect(on_damaged)
	combat_entered.connect(enter_combat)
	combat_exited.connect(exit_combat)
	load_abilities()
	calc_base_stats()
	cur_hp = base_stats.max_hp+stat_mods.max_hp
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	cur_mp = base_stats.max_mp+stat_mods.max_mp
	set_outline_color()
	EventBus.subscribe("GAMEPLAY_SETTINGS_CHANGED", self, "set_outline_color")
	init_schedule()

func calc_base_stats()->void:
	base_stats.max_hp = maxi(5+(star_stats.endurance-10)*2+(star_stats.strength-10), 5)
	base_stats.max_ap = maxi(2+(star_stats.agility-10)+(star_stats.resolve-10), 5)
	base_stats.max_mp = maxi(5+(star_stats.intelligence-10)+(star_stats.passion-10), 5)
	base_stats.avoidance = maxi(10+(star_stats.agility-10)*2+(star_stats.charisma-10), 0)
	base_stats.sequence = (star_stats.passion-10)+(star_stats.agility-10)

func update_stat_mod(stat_mod_name: String, amount: int)->void:
	if stat_mod_name not in stat_mods:
		printerr("Attempted to change stat mod "+stat_mod_name+" not in stat_mods")
	else:
		stat_mods[stat_mod_name] += amount

func refresh()->void:
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	stats_changed.emit()
	status_manager.tick_status()

func rest()->void:
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	cur_hp = base_stats.max_hp+stat_mods.max_hp
	cur_mp = base_stats.max_mp+stat_mods.max_mp
#endregion

#region Tasks
func init_schedule()->void:
	for task in schedule:
		task.user = self

func process_schedule()->void:
	if schedule.size() == 0 || in_combat || !active:
		return
	if !loop_schedule && schedule_executed:
		return
	if !use_timed_schedule:
		schedule[schedule_index].task_completed.connect(task_done)
		schedule[schedule_index].call_deferred("execute_task")

func task_done()->void:
	schedule[schedule_index].task_completed.disconnect(task_done)
	schedule_index = (schedule_index+1)%schedule.size()
	if (schedule_index == 0 && !loop_schedule) || !active:
		if schedule_index == 0:
			schedule_executed = true
		return
	process_schedule()
#endregion

#region Combat
func enter_combat()->void:
	in_combat = true

func exit_combat()->void:
	in_combat = false
	process_schedule()

func roll_sequence()->void:
	sequence = base_stats.sequence+stat_mods.sequence+randi_range(1,10)

func on_defeated()->void:
	EventBus.broadcast("PRINT_LOG","Defeated "+display_name)
	EventBus.broadcast("TILE_UNOCCUPIED", position)
	if taking_turn:
		ended_turn.emit(self)
	defeated.emit(self)
	defeated_at.emit(position)
	defeated_named.emit(display_name)
	deactivate()

func attack(_source: Ability, accuracy: int, amount: int)->void:
	if accuracy>=(base_stats.avoidance+stat_mods.avoidance):
		damage(amount)
	else:
		var text_ind_pos: Vector2 = text_indicator_shift+global_position
		EventBus.broadcast("MAKE_TEXT_INDICATOR", ["Miss!", text_ind_pos])

func damage(amount: int, ignore_defense: bool = false)->void:
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
	damaged.emit()
	stats_changed.emit()
	if cur_hp <= 0:
		anim_player.play("Character/defeat")

func end_turn()->void:
	while state_machine.current_state.state_id != "IDLE":
		await state_machine.state_changed
	remove_range_indicators()
	ended_turn.emit(self)
#endregion

#region Abilities
func select_ability(ability: Ability)->void:
	while state_machine.current_state.state_id == "MOVE":
		await state_machine.state_changed
	selected_ability = ability
	place_range_indicators(ability.get_valid_destinations(), ability.target_type)

func deselect_ability(will_reselect: bool = false)->void:
	selected_ability = null
	remove_range_indicators()
	if !will_reselect:
		ability_deselected.emit()

func get_abilities()->Array[Ability]:
	ability_scenes = []
	var arr: Array[Ability] = []
	for child in get_children():
		if child is Ability:
			arr.append(child)
			ability_scenes.append(child.scene_file_path)
	return arr

func load_abilities()->void:
	for child in get_children():
		if child is Ability:
			child.queue_free()
	for scn in ability_scenes:
		add_child(load(scn).instantiate())

func add_ability(ability_scene: PackedScene)->void:
	var ability: Ability = ability_scene.instantiate()
	add_child(ability)
	ability_scenes.append(ability.scene_file_path)
	abilities_changed.emit()

func anim_activate()->void:
	anim_activate_ability.emit()

func place_range_indicators(locations: Array[Vector2], target_type: Ability.target_type_choice)->void:
	for location in locations:
		var indicator: Sprite2D = range_indicator_scene.instantiate()
		if target_type == Ability.target_type_choice.target_self:
			indicator.modulate = Settings.gameplay.support_indicator_tint
		elif target_type == Ability.target_type_choice.target_allies:
			indicator.modulate = Settings.gameplay.support_indicator_tint
		elif target_type == Ability.target_type_choice.target_enemies:
			indicator.modulate = Settings.gameplay.attack_indicator_tint
		else:
			indicator.modulate = Settings.gameplay.attack_indicator_tint
		indicator.position = location-position
		add_child(indicator)
		range_indicators.append(indicator)

func remove_range_indicators()->void:
	while range_indicators.size()>0:
		range_indicators.pop_front().queue_free()
#endregion

#region Status
func add_status(status: Utility.Status)->void:
	status_manager.add_status(status)
	var info: Array = [status.display_name, text_indicator_shift+global_position, status.status_color]
	EventBus.broadcast("MAKE_TEXT_INDICATOR", info)

func process_status_action(action: Callable, args: Array)->void:
	deselect_ability()
	var prev_pos: Vector2 = position
	await action.call(args)
	if position != prev_pos:
		pos_changed.emit(self)
#endregion

#region Misc
func set_outline_color()->void:
	sprite.material.set_shader_parameter("outline_color", Color(Settings.gameplay.selection_tint, 180.0/255.0))

func select()->void:
	sprite.material.set_shader_parameter("width", 1)

func deselect()->void:
	sprite.material.set_shader_parameter("width", 0)
	if has_method("deselect_ability"):
		call("deselect_ability")

func on_damaged()->void:
	return

func deactivate()->void:
	active = false
	EventBus.broadcast("TILE_UNOCCUPIED", position)
	hide()

func activate(pos: Vector2)->void:
	active = true
	position = pos
	EventBus.broadcast("TILE_OCCUPIED", pos)
	show()
	process_schedule()
#endregion

#region Saving and Loading
func save_data(dir: String)->void:
	stop_move_order.emit()
	if active && schedule != []:
		schedule[schedule_index].pause.emit()
	state_machine.pause()
	while state_machine.current_state.critical_operation:
		await state_machine.current_state.critical_exited
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.WRITE)
	for var_name in to_save:
		file.store_var(var_name)
		file.store_var(get(var_name))
	file.store_var("END")
	file.close()
	if active && schedule != []:
		schedule[schedule_index].unpause.emit()
	state_machine.unpause()
	saved.emit(self)

func load_data(dir: String)->void:
	deselect()
	state_machine.pause()
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.READ)
	var var_name: String = file.get_var()
	while var_name != "END":
		set(var_name, file.get_var())
		var_name = file.get_var()
	file.close()
	load_abilities()
	state_machine.unpause()
	if active:
		activate(position)
	else:
		deactivate()
	loaded.emit(self)
#endregion
