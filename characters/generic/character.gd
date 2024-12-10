extends CharacterBody2D
class_name Character

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
@export var allies: Array[Character] = []
@export var ability_scenes: Array[String] = []
@export var display_name: String = "Name Here"
@export var text_indicator_shift: Vector2 = Vector2.UP*32
@onready var cur_ap: int
@onready var cur_mp: int
@onready var cur_hp: int
@onready var sprite: Sprite2D = %Sprite
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var state_machine: StateMachine = %StateMachine
@onready var status_manager: StatusManager = %StatusManager
@onready var target_position: Vector2 = position
@onready var range_indicator_scene: PackedScene = preload("res://misc/range_indicator.tscn")
var sequence: int
var in_combat: bool = false
var taking_turn: bool = false
var range_indicators: Array[Sprite2D] = []
var selected_ability: Ability = null
@warning_ignore("unused_signal") signal move_order(pos: Vector2)
@warning_ignore("unused_signal") signal stop_move_order
@warning_ignore("unused_signal") signal interact_order(object: Node2D)
@warning_ignore("unused_signal") signal ability_order(data: Array)
signal pos_changed
signal anim_activate_ability
signal ended_turn(character)
signal stats_changed
signal abilities_changed
signal defeated(character)
signal damaged

func _setup()->void:
	EventBus.subscribe("GLOBAL_TIMER_TIMEOUT", self, "refresh")
	status_manager.status_damage_ticked.connect(damage)
	status_manager.status_stat_mod_changed.connect(update_stat_mod)
	status_manager.status_action_occurred.connect(process_status_action)
	damaged.connect(on_damaged)
	load_abilities()
	calc_base_stats()
	cur_hp = base_stats.max_hp+stat_mods.max_hp
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	cur_mp = base_stats.max_mp+stat_mods.max_mp

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

func select_ability(ability: Ability)->void:
	while state_machine.current_state.state_id == "MOVE":
		await state_machine.state_changed
	selected_ability = ability
	place_range_indicators(ability.get_valid_destinations(), ability.target_type)

func deselect_ability()->void:
	selected_ability = null
	remove_range_indicators()

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

func add_status(status: Utility.Status)->void:
	status_manager.add_status(status)
	var info: Array = [status.display_name, text_indicator_shift+global_position, status.status_color]
	EventBus.broadcast(EventBus.Event.new("MAKE_TEXT_INDICATOR", info))

func roll_sequence()->void:
	sequence = base_stats.sequence+stat_mods.sequence+randi_range(1,10)

func anim_activate()->void:
	anim_activate_ability.emit()

func place_range_indicators(locations: Array[Vector2], target_type: Ability.target_type_choice)->void:
	for location in locations:
		var indicator: Sprite2D = range_indicator_scene.instantiate()
		if target_type == Ability.target_type_choice.target_self:
			indicator.modulate = Settings.support_indicator_tint
		elif target_type == Ability.target_type_choice.target_allies:
			indicator.modulate = Settings.support_indicator_tint
		elif target_type == Ability.target_type_choice.target_enemies:
			indicator.modulate = Settings.attack_indicator_tint
		else:
			indicator.modulate = Settings.attack_indicator_tint
		indicator.position = location-position
		add_child(indicator)
		range_indicators.append(indicator)

func remove_range_indicators()->void:
	while range_indicators.size()>0:
		range_indicators.pop_front().queue_free()

func refresh()->void:
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	stats_changed.emit()
	status_manager.tick_status()

func on_defeated()->void:
	EventBus.broadcast(EventBus.Event.new("PRINT_LOG","Defeated "+display_name))
	EventBus.broadcast(EventBus.Event.new("TILE_UNOCCUPIED", position))
	if taking_turn:
		ended_turn.emit(self)
	defeated.emit(self)
	queue_free()

func attack(_source: Ability, accuracy: int, amount: int)->void:
	if accuracy>=(base_stats.avoidance+stat_mods.avoidance):
		damage(amount)
	else:
		var text_ind_pos: Vector2 = text_indicator_shift+global_position
		EventBus.broadcast(EventBus.Event.new("MAKE_TEXT_INDICATOR", ["Miss!", text_ind_pos]))

func damage(amount: int, ignore_defense: bool = false)->void:
	var text_ind_pos: Vector2 = text_indicator_shift+global_position
	if amount >= base_stats.damage_threshold+stat_mods.damage_threshold || ignore_defense:
		cur_hp -= amount
		EventBus.broadcast(EventBus.Event.new("MAKE_TEXT_INDICATOR", [str(-amount), text_ind_pos]))
	else:
		var damage_reduced: int = maxi(amount-base_stats.defense-stat_mods.defense, 0)
		cur_hp -= damage_reduced
		if damage_reduced > 0:
			EventBus.broadcast(EventBus.Event.new("MAKE_TEXT_INDICATOR", [str(-damage_reduced), text_ind_pos]))
		else:
			EventBus.broadcast(EventBus.Event.new("MAKE_TEXT_INDICATOR", ["Blocked!", text_ind_pos]))
	damaged.emit()
	stats_changed.emit()
	if cur_hp <= 0:
		anim_player.play("defeat")

func end_turn()->void:
	while state_machine.current_state.state_id != "IDLE":
		await state_machine.state_changed
	remove_range_indicators()
	ended_turn.emit(self)

func select()->void:
	sprite.material.set_shader_parameter("line_color", Color(Settings.selection_tint, 180.0/255.0))

func deselect()->void:
	sprite.material.set_shader_parameter("line_color", Color(Settings.selection_tint, 0))
	if has_method("deselect_ability"):
		call("deselect_ability")

func process_status_action(action: Callable, args: Array)->void:
	deselect_ability()
	var prev_pos: Vector2 = position
	await action.call(args)
	if position != prev_pos:
		pos_changed.emit()

func on_damaged()->void:
	return

func activate()->void:
	return

func save_data(file: FileAccess)->void:
	file.store_var(position)
	file.store_var(star_stats)
	file.store_var(base_stats)
	file.store_var(ability_scenes)
	file.store_var(cur_hp)
	file.store_var(cur_ap)
	file.store_var(cur_mp)

func load_data(file: FileAccess)->void:
	deselect()
	position = file.get_var()
	star_stats = file.get_var()
	base_stats = file.get_var()
	ability_scenes = file.get_var()
	cur_hp = file.get_var()
	cur_ap = file.get_var()
	cur_mp = file.get_var()
	load_abilities()
