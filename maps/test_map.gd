extends GameMap

@onready var test_room_npc_scene: PackedScene = preload("res://characters/presets/test_room_npc.tscn")
@warning_ignore("unused_signal") signal test_room_combat_gate(sig_name)

func _extra_setup()->void:
	for child in get_children():
		if child is Enemy:
			child.defeated.connect(spawn_test_room_npc)

func spawn_test_room_npc(enemy: Enemy)->void:
	var pos: Vector2i = local_to_map(enemy.position)
	var npc: NPC = test_room_npc_scene.instantiate()
	npc.position = map_to_local(pos)
	update_occupied_tiles(pos, true)
	add_child(npc)
