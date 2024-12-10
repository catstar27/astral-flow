extends GameMap

@onready var test_room_npc_scene: PackedScene = preload("res://characters/presets/test_room_npc.tscn")
signal test_room_combat_gate(sig_name)

func _extra_setup()->void:
	for child in get_children():
		if child is Enemy:
			if !child.defeated.is_connected(spawn_test_room_npc):
				child.defeated.connect(spawn_test_room_npc)

func spawn_test_room_npc(enemy: Enemy)->void:
	var pos: Vector2i = local_to_map(enemy.position)
	var npc: NPC = test_room_npc_scene.instantiate()
	npc.position = map_to_local(pos)
	set_pos_occupied(map_to_local(pos))
	npc.combat_gate_open.connect(emit_combat_gate)
	add_child(npc)
	spawned[npc.name] = npc.scene_file_path
	npc.activate()

func emit_combat_gate()->void:
	test_room_combat_gate.emit("test_room_combat_gate")
