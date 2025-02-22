extends Interactive
class_name DamageActivationInteractive

enum damage_type_choice {blunt, electric, none}
@export var damage_type_required: damage_type_choice = damage_type_choice.none
@export var dialogue_unlocked: DialogicTimeline
var triggered: bool = false
var to_save: Array[StringName] = [
	"triggered"
]
signal unlocked(name: String)
signal saved(node)
signal loaded(node)

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

func save_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.WRITE)
	for var_name in to_save:
		file.store_var(var_name)
		file.store_var(get(var_name))
	file.store_var("END")
	saved.emit(self)

func load_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.READ)
	var var_name: String = file.get_var()
	while var_name != "END":
		set(var_name, file.get_var())
		var_name = file.get_var()
	file.close()
	loaded.emit(self)
