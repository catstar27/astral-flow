extends Character
class_name Enemy

enum ai_types {melee_aggressive, melee_safe}
@onready var combat_trigger: Area2D = %CombatTrigger
@export var ai_type: ai_types
var abilities: Array[Ability] = []

func _ready() -> void:
	_setup()
	abilities = get_abilities()

func _combat_trigger_entered(body: Node2D) -> void:
	if body is Player && !in_combat:
		GlobalRes.main.start_combat(body, self)

func take_turn()->void:
	call_deferred(str(ai_types.keys()[ai_type]))

func melee_aggressive()->void:
	abilities.sort_custom(func(x,y): return x.damage>y.damage)
	if !abilities[0].is_destination_valid(GlobalRes.player.position):
		target_position = GlobalRes.player.position
		move_order.emit()
		await move_finished
	if abilities[0].is_destination_valid(GlobalRes.player.position):
		while cur_ap>=abilities[0].ap_cost:
			await activate_ability(abilities[0], GlobalRes.player.position)
	end_turn()

func melee_safe()->void:
	return
