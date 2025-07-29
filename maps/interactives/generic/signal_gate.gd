@tool
extends Interactive
class_name SignalGate
## Gate that is locked until a set of signals are triggered
##
## Can optionally require a specific order for the signals

@export var open_texture: Texture ## Texture of the gate when locked
@export var open_sound: AudioStreamWAV ## Sound to play when the gate opens
@export var signals_needed: Array[String] = [] ## Signals needed for the gate to open
@export var auto_open: bool = false ## Whether the gate opens automatically when unlocked
@export var ordered: bool = false ## Whether the signals need to happen in the same order
@export var start_open: bool = false: ## Whether the gate starts open
	set(new_start):
		start_open = new_start
		if start_open:
			open(true)
		else:
			close()
@export_group("Dialogic") ## Variables relating to dialogic
@export var is_dialogic: bool = false ## Whether this gate uses dialogic signals
@export var dialogic_var: String ## Variable for this interactive's state stored in dialogic
var signal_index: int = 0 ## Current index of the signal being tracked
enum state { ## States the gate can be in
	locked, ## The gate is locked and closed
	unlocked, ## The gate is closed but not locked
	open ## The gate is open
}
@export_storage var cur_state: state = state.locked ## Current state of the gate
signal unlocked ## Emitted when unlocked
signal opened ## Emitted when opened
signal closed ## Emitted when closed

func _init() -> void:
	to_save.append("cur_state")

func setup_extra()->void:
	if cur_state != state.open:
		if is_dialogic && cur_state == state.locked:
			Dialogic.VAR.set(dialogic_var, signal_index)
	if is_dialogic:
		if !Dialogic.signal_event.is_connected(advance_unlock):
			Dialogic.signal_event.connect(advance_unlock)

func _interact_extra(_character: Character)->void:
	if cur_state == state.unlocked:
		open()

## Opens the gate, disabling its collision and opening the tile; can be done with or without sound
func open(quiet_open: bool = false)->void:
	while !is_node_ready():
		await ready
	cur_state = state.open
	allow_dialogue = false
	sprite.texture = open_texture
	collision.set_deferred("disabled", true)
	if !quiet_open && !Engine.is_editor_hint():
		EventBus.broadcast("PLAY_SOUND", [open_sound, "positional", global_position])
	if !Engine.is_editor_hint():
		for pos in occupied_positions:
			EventBus.broadcast("TILE_UNOCCUPIED", pos)
		EventBus.broadcast("QUEST_EVENT", "open_door:"+id)
	opened.emit()
	collision_active = false

## Closes the gate, even if the signals are fulfilled
func close()->void:
	while !is_node_ready():
		await ready
	cur_state = state.locked
	allow_dialogue = true
	sprite.texture = texture
	collision.set_deferred("disabled", false)
	if !Engine.is_editor_hint():
		EventBus.broadcast("PLAY_SOUND", [open_sound, "positional", global_position])
		for pos in occupied_positions:
			EventBus.broadcast("TILE_OCCUPIED", [pos, self])
	closed.emit()
	collision_active = true

## Advances the unlock in the gate; analyzes the given signal, which must pass a string
func advance_unlock(signal_event)->void:
	if signal_event is Dictionary || !signal_event in signals_needed || cur_state == state.open:
		return
	if !signal_index>=signals_needed.size():
		if signal_event==signals_needed[signal_index]:
			signal_index += 1
			if signal_index>=signals_needed.size():
				cur_state = state.unlocked
				EventBus.broadcast("QUEST_EVENT", "unlock_door:"+id)
				unlocked.emit()
				allow_dialogue = false
				if auto_open:
					open()
		elif ordered:
			signal_index = 0
	if is_dialogic:
		Dialogic.VAR.set(dialogic_var, signal_index)

#region Save and Load
## Executes before making the save dict
func pre_save()->void:
	return

## Executes after making the save dict
func post_save()->void:
	saved.emit(self)

## Executes before loading data
func pre_load()->void:
	return

## Executes after loading data
func post_load()->void:
	super.post_load()
	if cur_state == state.open:
		open(true)
	elif cur_state == state.unlocked:
		allow_dialogue = false
	loaded.emit(self)
#endregion
