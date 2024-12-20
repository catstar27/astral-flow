extends Interactive
class_name DamageActivationInteractive

enum damage_type_choice {blunt, electric, none}
@export var damage_type_required: damage_type_choice = damage_type_choice.none
@export var dialogue_unlocked: DialogicTimeline
var triggered: bool = false
signal unlocked(name: String)

func setup_extra()->void:
	if triggered:
		unlock()

func attack(source: Ability, _accuracy: int, _amount: int)->void:
	if triggered:
		return
	if damage_type_required != damage_type_choice.none:
		if !source.damage_type == damage_type_required:
			return
	unlock()

func unlock()->void:
	triggered = true
	dialogue_timeline = dialogue_unlocked
	unlocked.emit("unlocked")
	sprite.frame = 1

func save_data(file: FileAccess)->void:
	file.store_var(triggered)

func load_data(file: FileAccess)->void:
	triggered = file.get_var()
