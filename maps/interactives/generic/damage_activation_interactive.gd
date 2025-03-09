extends Interactive
class_name DamageActivationInteractive
## Interactive that emits a signal when dealt damage matching a specific damage type

## Required damage type to trigger this interactive
@export var damage_type_required: Ability.damage_type_options = Ability.damage_type_options.none
@export var dialogue_unlocked: DialogicTimeline ## Dialogue to play when this is unlocked
var triggered: bool = false ## Whether this has been triggered
var to_save: Array[StringName] = [ ## Variables to save
	"triggered"
]
signal unlocked(name: String) ## Emitted when this is unlocked
signal saved(node) ## Emitted when this is saved
signal loaded(node) ## Emitted when this is loaded

## Called when this is dealt damage; triggers if the type matches
func damage(_source: Node, _amount: int, damage_type: Ability.damage_type_options, _ignore_armor: bool = false)->void:
	if triggered:
		return
	if damage_type == damage_type_required || damage_type_required == Ability.damage_type_options.none:
		trigger()

## Triggers this interactive
func trigger(quiet_unlock: bool = false)->void:
	triggered = true
	dialogue_timeline = dialogue_unlocked
	if !quiet_unlock:
		unlocked.emit("unlocked")
	sprite.frame = 1

#region Save and Load
## Saves the data
func save_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.WRITE)
	for var_name in to_save:
		file.store_var(var_name)
		file.store_var(get(var_name))
	file.store_var("END")
	file.close()
	saved.emit(self)

## Loads the data
func load_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.READ)
	var var_name: String = file.get_var()
	while var_name != "END":
		set(var_name, file.get_var())
		var_name = file.get_var()
	file.close()
	if triggered:
		trigger(true)
	loaded.emit(self)
#endregion
