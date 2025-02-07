extends Character
class_name Enemy

enum ai_types {melee_aggressive, melee_safe}
@onready var combat_trigger: Area2D = %CombatTrigger
@export var ai_type: ai_types
@export var defeat_signal: String
var watching: Dictionary = {}
var abilities: Array[Ability] = []
var target: Character = null

func _ready() -> void:
	_setup()
	abilities = get_abilities()
	#pos_changed.connect(check_rays)

func _process(_delta: float) -> void:
	check_rays()

func check_rays(_character: Character = null)->void:
	for character in watching:
		check_ray(character)

func check_ray(character: Character)->void:
	watching[character].target_position = character.position-position
	if watching[character].get_collider() == character:
		try_combat(character)

func _combat_trigger_entered(body: Node2D) -> void:
	if body is Character && body != self:
		var ray: RayCast2D = RayCast2D.new()
		add_child(ray)
		ray.target_position = body.position
		watching[body] = ray
		body.pos_changed.connect(check_ray)
		check_ray(body)

func _combat_trigger_exited(body: Node2D) -> void:
	if body is Character && body != self:
		body.pos_changed.disconnect(check_ray)
		remove_child(watching[body])
		watching[body].queue_free()
		watching.erase(body)

func try_combat(character: Character)->void:
	if character is Player && !in_combat:
		target = character
		var participants: Array[Character] = [character, self]
		EventBus.broadcast("START_COMBAT", participants)

func take_turn()->void:
	call_deferred(str(ai_types.keys()[ai_type]))

func melee_aggressive()->void:
	abilities.sort_custom(func(x,y): return x.damage>y.damage)
	if !abilities[0].is_destination_valid(target.position):
		move_order.emit(target.position)
		await get_tree().create_timer(.01).timeout
		while state_machine.current_state.state_id != "IDLE":
			await state_machine.state_changed
	if abilities[0].is_destination_valid(target.position):
		while cur_ap>=abilities[0].ap_cost:
			ability_order.emit([abilities[0], target.position])
			while state_machine.current_state.state_id != "IDLE":
				await state_machine.state_changed
			if cur_hp <= 0:
				return
	end_turn()

func melee_safe()->void:
	return
