extends CharacterBody2D
class_name Character

@export var move_speed: float = 5.0
@export var max_ap: int = 5
@export var max_mp: int = 5
@export var max_hp: int = 10
@onready var cur_ap: int = max_ap
@onready var cur_mp: int = max_mp
@onready var cur_hp: int = max_hp
var in_combat: bool = false
var interactive_in_range: Interactive = null

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

func _enter_interactive_area(this_interactive: Interactive)->void:
	interactive_in_range = this_interactive

func _exit_interactive_area()->void:
	interactive_in_range = null

func interact()->void:
	interactive_in_range.call_deferred("_interacted", self)
