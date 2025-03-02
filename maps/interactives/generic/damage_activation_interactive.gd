extends Interactive
class_name DamageActivationInteractive

@export var damage_type_required: Ability.damage_type_options = Ability.damage_type_options.none
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

func damage(_source: Node, _amount: int, damage_type: Ability.damage_type_options, _ignore_armor: bool = false)->void:
	if triggered:
		return
	if damage_type == damage_type_required:
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
