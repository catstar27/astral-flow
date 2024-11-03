extends Node

var map: GameMap
signal globals_initialized

func update_var(new_value)->void:
	if new_value is GameMap:
		map = new_value
	if map != null:
		globals_initialized.emit()
