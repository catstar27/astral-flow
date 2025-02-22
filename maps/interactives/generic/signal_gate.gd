extends Interactive
class_name SignalGate

@export var locked_texture: Texture
@export var signals_needed: Array[String] = []
@export var auto_open: bool = false
@export var open_sound: AudioStreamWAV
var signal_index: int = 0
enum state {locked, unlocked, open}
var cur_state: state = state.locked
var to_save: Array[StringName] = [
	"cur_state"
]
signal saved(node)
signal loaded(node)

func setup_extra()->void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = 64*Vector2(float(dimensions.x)/scale.x, float(dimensions.y)/scale.y)
	if cur_state != state.open:
		collision.shape = shape
		sprite.texture = locked_texture
	_calc_occupied()

func _interacted(_character: Character)->void:
	if cur_state == state.locked:
		audio.play()
		if dialogue_timeline != null:
			EventBus.broadcast("ENTER_DIALOGUE", [dialogue_timeline, false])
		interacted.emit()
	elif cur_state == state.unlocked:
		open()

func open()->void:
	cur_state = state.open
	sprite.texture = texture
	collision.set_deferred("disabled", true)
	if !SaveLoad.loading && !NavMaster.map_loading:
		EventBus.broadcast("PLAY_SOUND", [open_sound, "positional", global_position])
	EventBus.broadcast("TILE_UNOCCUPIED", position)
	interacted.emit()
	collision_active = false

func advance_unlock(signal_event: String)->void:
	if !signal_event in signals_needed:
		return
	if !signal_index>=signals_needed.size():
		if signal_event==signals_needed[signal_index]:
			signal_index += 1
			if signal_index>=signals_needed.size():
				cur_state = state.unlocked
				if auto_open:
					open()

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
	if cur_state == state.open:
		open()
	loaded.emit(self)
