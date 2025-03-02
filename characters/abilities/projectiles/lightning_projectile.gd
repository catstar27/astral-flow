extends Projectile
class_name  LightningProjectile
## Lightning-like projectile

func shoot(destination: Vector2)->void:
	var final_scale: Vector2 = Vector2(scale.x, ability.user.position.distance_to(destination)/NavMaster.tile_size)
	rotation = get_angle_to(destination)+PI/2
	scale = Vector2(1,.01)
	texture_scale = Vector2(1,.01)
	create_tween().tween_property(self, "texture_scale", final_scale, .2)
	await create_tween().tween_property(self, "scale", final_scale, .2).finished
	await get_tree().create_timer(.1).timeout
	queue_free()
