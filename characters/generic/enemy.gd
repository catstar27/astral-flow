extends Character
class_name Enemy
## Basic enemy class that uses raycasts to initiate combat with players

@onready var combat_trigger: Area2D = %CombatTrigger ## Area that tracks other characters for combat
var watching: Dictionary[Node2D, RayCast2D] = {} ## Character/raycast pairs for characters in combat trigger

func _process(_delta: float) -> void:
	if active:
		check_rays()

## Checks every ray this enemy is casting
func check_rays(_character: Character = null)->void:
	for character in watching:
		check_ray(character)

## Checks a ray corresponding to the character it is watching for
## Tries to start combat if the ray is colliding with its target
func check_ray(character: Character)->void:
	watching[character].target_position = character.position-position
	if watching[character].get_collider() == character:
		try_combat(character)

## Creates a new ray to track the character that entered the combat trigger
func _combat_trigger_entered(body: Node2D) -> void:
	if body is Character && body != self:
		var ray: RayCast2D = RayCast2D.new()
		ray.set_collision_mask_value(1, true)
		ray.set_collision_mask_value(2, true)
		add_child(ray)
		ray.target_position = body.position
		watching[body] = ray
		body.pos_changed.connect(check_ray)
		check_ray(body)

## Removes the ray corresponding to the tracked character
func _combat_trigger_exited(body: Node2D) -> void:
	if body is Character && body != self:
		body.pos_changed.disconnect(check_ray)
		remove_child(watching[body])
		watching[body].queue_free()
		watching.erase(body)

## Attempts to initiate combat with the given character
func try_combat(character: Character)->void:
	if !active:
		return
	if character is Player && !in_combat:
		combat_target = character
		var participants: Array[Character] = [character, self]
		EventBus.broadcast("START_COMBAT", participants)
