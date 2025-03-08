extends Interactive
class_name SignalGate
## Gate that is locked until a set of signals are triggered
##
## Can optionally require a specific order for the signals

@export var locked_texture: Texture ## Texture of the gate when locked
@export var open_sound: AudioStreamWAV ## Sound to play when the gate opens
@export var signals_needed: Array[String] = [] ## Signals needed for the gate to open
@export var auto_open: bool = false ## Whether the gate opens automatically when unlocked
@export var ordered: bool = false ## Whether the signals need to happen in the same order
@export_group("Dialogic") ## Variables relating to dialogic
@export var is_dialogic: bool = false ## Whether this gate uses dialogic signals
@export var dialogic_var: String ## 
var signal_index: int = 0 ## Current index of the signal being tracked
enum state { ## States the gate can be in
	locked, ## The gate is locked and closed
	unlocked, ## The gate is closed but not locked
	open ## The gate is open
}
var cur_state: state = state.locked ## Current state of the gate
var to_save: Array[StringName] = [ ## Variables to save
	"cur_state"
]
signal saved(node: SignalGate) ## Emitted when saved
signal loaded(node: SignalGate) ## Emitted when loaded

func setup_extra()->void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = 64*Vector2(float(dimensions.x)/scale.x, float(dimensions.y)/scale.y)
	if cur_state != state.open:
		collision.shape = shape
		sprite.texture = locked_texture
		if is_dialogic && cur_state == state.locked:
			Dialogic.VAR.set(dialogic_var, signal_index)
	if is_dialogic:
		if !Dialogic.signal_event.is_connected(advance_unlock):
			Dialogic.signal_event.connect(advance_unlock)
	_calc_occupied()

func _interact_extra(_character: Character)->void:
	if cur_state == state.unlocked:
		open()

## Opens the gate, disabling its collision and opening the tile; can be done with or without sound
func open(quiet_open: bool = false)->void:
	cur_state = state.open
	allow_dialogue = false
	sprite.texture = texture
	collision.set_deferred("disabled", true)
	if !quiet_open:
		EventBus.broadcast("PLAY_SOUND", [open_sound, "positional", global_position])
	for pos in occupied_positions:
		EventBus.broadcast("TILE_UNOCCUPIED", pos)
	interacted.emit()
	collision_active = false

## Closes the gate, even if the signals are fulfilled
func close()->void:
	cur_state = state.locked
	allow_dialogue = true
	sprite.texture = locked_texture
	collision.set_deferred("disabled", false)
	EventBus.broadcast("PLAY_SOUND", [open_sound, "positional", global_position])
	for pos in occupied_positions:
		EventBus.broadcast("TILE_OCCUPIED", pos)
	interacted.emit()
	collision_active = true

## Advances the unlock in the gate; analyzes the given signal, which must pass a string
func advance_unlock(signal_event: String)->void:
	if !signal_event in signals_needed:
		return
	if !signal_index>=signals_needed.size():
		if signal_event==signals_needed[signal_index]:
			signal_index += 1
			if signal_index>=signals_needed.size():
				cur_state = state.unlocked
				allow_dialogue = false
				if auto_open:
					open()
		elif ordered:
			signal_index = 0
	if is_dialogic:
		Dialogic.VAR.set(dialogic_var, signal_index)

#region Save and Load
## Saves the gate's data
func save_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.WRITE)
	for var_name in to_save:
		file.store_var(var_name)
		file.store_var(get(var_name))
	file.store_var("END")
	saved.emit(self)

## Loads the gate's data
func load_data(dir: String)->void:
	var file: FileAccess = FileAccess.open(dir+name+".dat", FileAccess.READ)
	var var_name: String = file.get_var()
	while var_name != "END":
		set(var_name, file.get_var())
		var_name = file.get_var()
	file.close()
	if cur_state == state.open:
		open(true)
	elif cur_state == state.unlocked:
		allow_dialogue = false
	loaded.emit(self)
#endregion
