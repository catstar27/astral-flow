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
@export var display_name: String = "Name Here"
@onready var cur_ap: int
@onready var cur_mp: int
@onready var cur_hp: int
@onready var sprite: Sprite2D = %Sprite
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var state_machine: StateMachine = %StateMachine
@onready var target_position: Vector2 = position
@onready var range_indicator_scene: PackedScene = preload("res://misc/range_indicator.tscn")
var state: State = null
var sequence: int
var in_combat: bool = false
var taking_turn: bool = false
var stop_move: bool = false
var using_ability: bool = false
var range_indicators: Array[Sprite2D] = []
var selected_ability: Ability = null
var interact_target: Node2D = null
signal move_order(pos: Vector2)
signal move_processed
@warning_ignore("unused_signal") signal move_finished
signal stop_move_order
signal interact_order(object: Node2D)
signal interact_processed
signal anim_activate_ability
signal ability_used
signal ended_turn(character)
signal stats_changed
signal abilities_changed
signal defeated(character)

func _setup()->void:
	EventBus.subscribe("GLOBAL_TIMER_TIMEOUT", self, "refresh")
	interact_order.connect(process_interact)
	move_order.connect(process_move)
	stop_move_order.connect(stop_move_now)
	calc_base_stats()
	cur_hp = base_stats.max_hp+stat_mods.max_hp
	cur_ap = base_stats.max_ap+stat_mods.max_ap
	cur_mp = base_stats.max_mp+stat_mods.max_mp

func calc_base_stats()->void:
	base_stats.max_hp = maxi(5+(star_stats.endurance-10)*2+(star_stats.strength-10), 5)
	base_stats.max_ap = maxi(5+(star_stats.agility-10)+(star_stats.resolve-10), 5)
	base_stats.max_mp = maxi(5+(star_stats.intelligence-10)+(star_stats.passion-10), 5)
	base_stats.avoidance = maxi(20+(star_stats.agility-10)*2+(star_stats.charisma-10), 0)
	base_stats.sequence = (star_stats.passion-10)+(star_stats.agility-10)

func select_ability(ability: Ability)->void:
	selected_ability = ability
	place_range_indicators(ability.get_valid_destinations(), ability.target_type)

func deselect_ability()->void:
	selected_ability = null
	remove_range_indicators()

func activate_ability(ability: Ability, destination: Vector2)->void:
	if using_ability:
		return
	if !ability.is_destination_valid(destination):
		EventBus.broadcast(EventBus.Event.new("PRINT_LOG","Invalid Target!"))
		return
	if ability.ap_cost>cur_ap:
		EventBus.broadcast(EventBus.Event.new("PRINT_LOG","Not enough ap"))
		return
	if ability.mp_cost>cur_mp:
		EventBus.broadcast(EventBus.Event.new("PRINT_LOG","Not enough mp"))
		return
	remove_range_indicators()
	using_ability = true
	cur_ap -= ability.ap_cost
	cur_mp -= ability.mp_cost
	stats_changed.emit()
	anim_player.play("melee")
	await anim_activate_ability
	ability.call_deferred("activate", destination)
	await anim_player.animation_finished
	using_ability = false
	ability_used.emit()
	after_ability()

func after_ability()->void:
	return

func add_ability(ability_scene: PackedScene)->void:
	var ability: Ability = ability_scene.instantiate()
	ability.position = Vector2.ZERO
	add_child(ability)
	abilities_changed.emit()

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

func _defeated()->void:
	EventBus.broadcast(EventBus.Event.new("PRINT_LOG","Defeated "+display_name))
	EventBus.broadcast(EventBus.Event.new("TILE_UNOCCUPIED", position))
	if taking_turn:
		ended_turn.emit(self)
	defeated.emit(self)
	queue_free()

func damage(_source: Ability, accuracy: int, amount: int)->void:
	print(accuracy)
	print(base_stats.avoidance+stat_mods.avoidance)
	if accuracy>=(base_stats.avoidance+stat_mods.avoidance):
		if amount >= base_stats.damage_threshold+stat_mods.damage_threshold:
			cur_hp -= amount
		else:
			cur_hp -= maxi(amount-base_stats.defense-stat_mods.defense, 0)
		stats_changed.emit()
		if cur_hp <= 0:
			_defeated()

func process_interact(target)->void:
	interact_target = target
	interact_processed.emit()

func process_move(pos: Vector2)->void:
	target_position = pos
	move_processed.emit()

func stop_move_now()->void:
	if state_machine.current_state.state_id == "MOVE":
		stop_move = true

func end_turn()->void:
	ended_turn.emit(self)

func select()->void:
	var line_color: Color = sprite.material.get_shader_parameter("line_color")
	sprite.material.set_shader_parameter("line_color", Color(line_color, 180.0/255.0))

func deselect()->void:
	var line_color: Color = sprite.material.get_shader_parameter("line_color")
	sprite.material.set_shader_parameter("line_color", Color(line_color, 0))
	if has_method("deselect_ability"):
		call("deselect_ability")

func get_abilities()->Array[Ability]:
	var arr: Array[Ability] = []
	for child in get_children():
		if child is Ability:
			arr.append(child)
	return arr
