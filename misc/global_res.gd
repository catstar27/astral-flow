extends Node

var player: Player
var selection_cursor: SelectionCursor
var map: GameMap
var hud: Control
var selection_cursor_scene: PackedScene = preload("res://misc/selection_cursor.tscn")
var player_scene: PackedScene = preload("res://characters/player.tscn")
