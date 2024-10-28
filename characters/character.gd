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
@onready var cur_ap: int = base_stats.max_ap
@onready var cur_mp: int = base_stats.max_mp
@onready var cur_hp: int = base_stats.max_hp
@onready var sprite: Sprite2D = %Sprite
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var target_position: Vector2 = position
@onready var range_indicator_scene: PackedScene = preload("res://misc/range_indicator.tscn")
var sequence: int
var in_combat: bool = false
var moving: bool = false
var stop_move: bool = false
var range_indicators: Array[Sprite2D] = []
signal move_order
signal interact_order(object: Interactive)
signal anim_activate_ability
signal end_turn
signal stats_changed

func _setup()->void:
	GlobalRes.timer.timeout.connect(refresh)
	move_order.connect(move)
	interact_order.connect(interact)

func activate_ability(ability: Ability, destination: Vector2)->void:
	if !ability.is_destination_valid(destination):
		print("Invalid Target!")
		return
	if ability.ap_cost>cur_ap && in_combat:
		print("Not enough ap")
		return
	if ability.mp_cost>cur_mp:
		print("Not enough mp")
		return
	cur_ap -= ability.ap_cost
	cur_mp -= ability.mp_cost
	stats_changed.emit()
	anim_player.play("melee")
	await anim_activate_ability
	ability.activate(destination)

func roll_sequence()->void:
	sequence = (base_stats.agility-10)+(base_stats.passion-10)+randi_range(1,10)

func anim_activate()->void:
	anim_activate_ability.emit()

func place_range_indicators(locations: Array[Vector2])->void:
	for location in locations:
		var indicator: Sprite2D = range_indicator_scene.instantiate()
		indicator.modulate = GlobalRes.selection_cursor.tint
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
	print("Defeated "+name)
	GlobalRes.map.update_occupied_tiles(GlobalRes.map.local_to_map(position), false)
	queue_free()

func damage(_source: Ability, amount: int)->void:
	cur_hp -= amount
	stats_changed.emit()
	if cur_hp <= 0:
		_defeated()

func interact(interactive: Interactive)->void:
	var reached: bool = await move()
	if reached:
		interactive.call_deferred("_interacted", self)

func select()->void:
	var line_color: Color = sprite.material.get_shader_parameter("line_color")
	sprite.material.set_shader_parameter("line_color", Color(line_color, 180.0/255.0))

func deselect()->void:
	var line_color: Color = sprite.material.get_shader_parameter("line_color")
	sprite.material.set_shader_parameter("line_color", Color(line_color, 0))

func get_abilities()->Array[Ability]:
	var arr: Array[Ability] = []
	for child in get_children():
		if child is Ability:
			arr.append(child)
	return arr

func move():
	if moving:
		return
	if in_combat && cur_ap == 0:
		return
	moving = true
	var cur_target: Vector2 = target_position
	var path: Array[Vector2i] = GlobalRes.map.get_nav_path(position, target_position)
	path.pop_front()
	for cell in path:
		if cur_ap == 0:
				print("No ap for movement!")
				moving = false
				return
		if stop_move:
			target_position = position
			stop_move = false
			moving = false
			return
		var prev_cell: Vector2i = GlobalRes.map.local_to_map(position)
		GlobalRes.map.update_occupied_tiles(cell, true)
		await create_tween().tween_property(self, "position", GlobalRes.map.map_to_local(cell), .2).finished
		GlobalRes.map.update_occupied_tiles(prev_cell, false)
		if in_combat:
			cur_ap -= 1
			stats_changed.emit()
		if cur_target != target_position:
			moving = false
			move_order.emit()
			return
	moving = false
	return
