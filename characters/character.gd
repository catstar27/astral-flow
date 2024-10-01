extends CharacterBody2D
class_name Character

@export var move_speed: float = 5.0
@export var max_ap: int = 5
@export var max_mp: int = 5
@export var max_hp: int = 10
@onready var cur_ap: int = max_ap
@onready var cur_mp: int = max_mp
@onready var cur_hp: int = max_hp
@onready var sprite: Sprite2D = %Sprite
var in_combat: bool = false
var moving: bool = false

func activate_ability(ability: Ability)->void:
	if ability.ap_cost>cur_ap && in_combat:
		print("Not enough ap")
		return
	if ability.mp_cost>cur_mp:
		print("Not enough mp")
		return
	cur_ap -= ability.ap_cost
	cur_mp -= ability.mp_cost
	ability.activate()

func _defeated()->void:
	print("Defeated "+name)
	queue_free()

func _take_damage(_source: Ability, amount: int)->void:
	cur_hp -= amount
	if cur_hp <= 0:
		_defeated()

func interact(interactive: Interactive)->void:
	interactive.call_deferred("_interacted", self)

func select()->void:
	var line_color: Color = sprite.material.get_shader_parameter("line_color")
	sprite.material.set_shader_parameter("line_color", Color(line_color, 180.0/255.0))

func deselect()->void:
	var line_color: Color = sprite.material.get_shader_parameter("line_color")
	sprite.material.set_shader_parameter("line_color", Color(line_color, 0))

func move(target_position: Vector2i)->void:
	if moving:
		return
	moving = true
	var path: Array[Vector2i] = GlobalRes.map.get_nav_path(position, target_position)
	for cell in path:
		await create_tween().tween_property(self, "position", GlobalRes.map.map_to_local(cell), .2).finished
	moving = false
