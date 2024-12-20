extends Ability

var lightning_scn: PackedScene = preload("res://textures/lightning.tscn")

func activate(destination: Vector2)->void:
	var lightning: Polygon2D = lightning_scn.instantiate()
	var final_scale: Vector2 = Vector2(lightning.scale.x, user.position.distance_to(destination)/NavMaster.tile_size)
	lightning.rotation = get_angle_to(destination)+PI/2
	lightning.scale = Vector2(1,.01)
	lightning.texture_scale = Vector2(1,.01)
	add_child(lightning)
	play_sound()
	create_tween().tween_property(lightning, "texture_scale", final_scale, .2)
	await create_tween().tween_property(lightning, "scale", final_scale, .2).finished
	deal_damage(get_target(destination))
	activated.emit()
	await get_tree().create_timer(.1).timeout
	for child in get_children():
		child.queue_free()
