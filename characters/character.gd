extends CharacterBody2D
class_name Character

@export var max_ap: int = 5
@export var max_mp: int = 5
@export var max_hp: int = 10
@onready var cur_ap: int = max_ap
@onready var cur_mp: int = max_mp
@onready var cur_hp: int = max_hp
@onready var sprite: Sprite2D = %Sprite
@onready var anim_player: AnimationPlayer = %AnimationPlayer
@onready var target_position: Vector2 = position
@onready var range_indicator_scene: PackedScene = preload("res://misc/range_indicator.tscn")
var in_combat: bool = false
var moving: bool = false
var range_indicators: Array[Sprite2D] = []
signal move_interrupt
signal anim_activate_ability

func _setup()->void:
	GlobalRes.timer.timeout.connect(refresh_safe)

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
	anim_player.play("melee")
	await anim_activate_ability
	ability.activate(destination)

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

func refresh_safe()->void:
	if in_combat:
		return
	cur_ap = max_ap

func _defeated()->void:
	print("Defeated "+name)
	queue_free()

func _take_damage(_source: Ability, amount: int)->void:
	cur_hp -= amount
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

func move()->bool:
	if moving:
		return false
	if in_combat && cur_ap == 0:
		return false
	moving = true
	GlobalRes.map.update_occupied_tiles(GlobalRes.map.local_to_map(position), false)
	var cur_target: Vector2 = target_position
	var path: Array[Vector2i] = GlobalRes.map.get_nav_path(position, target_position)
	for cell in path:
		if in_combat:
			cur_ap -= 1
		await create_tween().tween_property(self, "position", GlobalRes.map.map_to_local(cell), .2).finished
		if cur_target != target_position:
			moving = false
			move_interrupt.emit()
			return false
	GlobalRes.map.update_occupied_tiles(GlobalRes.map.local_to_map(position), true)
	moving = false
	return true
