extends CharacterBody2D
class_name Character

@export var base_stats: Dictionary = {
	"max_ap": 5,
	"max_mp": 5,
	"max_hp": 10,
	"intelligence": 10,
	"agility": 10,
	"strength": 10,
	"constitution": 10,
	"charisma": 10,
	"perception": 10,
	"passion": 10
}
@export var allies: Array[Character] = []
@export var display_name: String = "Name Here"
@onready var cur_ap: int = base_stats.max_ap
@onready var cur_mp: int = base_stats.max_mp
@onready var cur_hp: int = base_stats.max_hp
@onready var sprite: Sprite2D = %Sprite
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var target_position: Vector2 = position
@onready var range_indicator_scene: PackedScene = preload("res://misc/range_indicator.tscn")
var damage_reduction: int = 0
var sequence: int
var in_combat: bool = false
var taking_turn: bool = false
var moving: bool = false
var stop_move: bool = false
var using_ability: bool = false
var range_indicators: Array[Sprite2D] = []
var selected_ability: Ability = null
signal move_order
signal move_finished
signal interact_order(object: Interactive)
signal anim_activate_ability
signal ability_used
signal ended_turn(character)
signal stats_changed
signal abilities_changed
signal defeated(character)

func _setup()->void:
	EventBus.subscribe("GLOBAL_TIMER_TIMEOUT", self, "refresh")
	move_order.connect(move)
	interact_order.connect(interact)

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
	sequence = (base_stats.agility-10)+(base_stats.passion-10)+randi_range(1,10)

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
	cur_ap = base_stats.max_ap
	stats_changed.emit()

func _defeated()->void:
	EventBus.broadcast(EventBus.Event.new("PRINT_LOG","Defeated "+display_name))
	EventBus.broadcast(EventBus.Event.new("TILE_UNOCCUPIED", position))
	if taking_turn:
		ended_turn.emit(self)
	defeated.emit(self)
	queue_free()

func damage(_source: Ability, amount: int)->void:
	cur_hp -= clampi(amount-damage_reduction, 0, 999999999)
	stats_changed.emit()
	if cur_hp <= 0:
		_defeated()

func interact(interact_target)->void:
	var reached: bool = await move()
	if reached:
		interact_target.call_deferred("_interacted", self)

func end_turn()->void:
	if using_ability:
		await ability_used
	if moving:
		await move_finished
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

func move()->bool:
	if moving:
		return false
	if in_combat && cur_ap == 0:
		return false
	moving = true
	var cur_target: Vector2 = target_position
	var path: Array[Vector2] = GlobalRes.map.get_nav_path(position, target_position)
	if path.pop_front() != position:
		return false
	for pos in path:
		if cur_ap == 0:
				EventBus.broadcast(EventBus.Event.new("PRINT_LOG","No ap for movement!"))
				moving = false
				move_finished.emit()
				return false
		if stop_move:
			target_position = position
			stop_move = false
			moving = false
			move_finished.emit()
			return false
		var prev_pos: Vector2 = position
		EventBus.broadcast(EventBus.Event.new("TILE_OCCUPIED", pos))
		await create_tween().tween_property(self, "position", pos, .2).finished
		EventBus.broadcast(EventBus.Event.new("TILE_UNOCCUPIED", prev_pos))
		if in_combat:
			cur_ap -= 1
			stats_changed.emit()
		if cur_target != target_position:
			moving = false
			move_order.emit()
			return false
	moving = false
	move_finished.emit()
	return true
