extends Character
class_name Enemy

enum ai_types {melee_aggressive, melee_safe}
@onready var combat_trigger: Area2D = %CombatTrigger
@export var ai_type: ai_types
@export var defeat_signal: String
var abilities: Array[Ability] = []
var target: Character = null

func _ready() -> void:
	_setup()
	abilities = get_abilities()

func _combat_trigger_entered(body: Node2D) -> void:
	if body is Player && !in_combat:
		target = body
		var participants: Array[Character] = [body, self]
		EventBus.broadcast(EventBus.Event.new("START_COMBAT", participants))

func take_turn()->void:
	call_deferred(str(ai_types.keys()[ai_type]))

func melee_aggressive()->void:
	abilities.sort_custom(func(x,y): return x.damage>y.damage)
	if !abilities[0].is_destination_valid(target.position):
		target_position = target.position
		move_order.emit()
		await move_finished
	if abilities[0].is_destination_valid(target.position):
		while cur_ap>=abilities[0].ap_cost:
			await activate_ability(abilities[0], target.position)
			if cur_hp <= 0:
				return
	end_turn()

func melee_safe()->void:
	return
