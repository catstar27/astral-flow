extends Node2D

func _ready() -> void:
	GlobalRes.player = %Player
	GlobalRes.map = %TestMap
	GlobalRes.selection_cursor = %SelectionCursor
