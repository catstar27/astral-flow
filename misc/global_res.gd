extends Node

var main: Node2D
var player: Player
var selection_cursor: SelectionCursor
var map: GameMap
var hud: HUD
var timer: Timer
var current_timeline: Node = null
var selection_cursor_scene: PackedScene = preload("res://misc/selection_cursor.tscn")
var player_scene: PackedScene = preload("res://characters/player.tscn")
signal globals_initialized

func update_var(new_value)->void:
	if new_value is Player:
		player = new_value
	if new_value is SelectionCursor:
		selection_cursor = new_value
	if new_value is GameMap:
		map = new_value
	if new_value is HUD:
		hud = new_value
	if new_value is Timer:
		timer = new_value
	if player != null && selection_cursor != null && map != null && hud != null && timer != null:
		globals_initialized.emit()
