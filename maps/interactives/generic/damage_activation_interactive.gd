extends Interactive
class_name DamageActivationInteractive

enum damage_type_choice {blunt, electric, none}
@export var damage_type_required: damage_type_choice = damage_type_choice.none
@export var dialogue_unlocked: String
var triggered: bool = false
signal unlocked(name: String)

func damage(source: Ability, amount: int)->void:
	if triggered:
		return
	if damage_type_required != damage_type_choice.none:
		if !source.damage_type == damage_type_required:
			return
	dialogue_timeline = load(dialogue_unlocked)
	unlocked.emit("unlocked")
	sprite.frame = 1
