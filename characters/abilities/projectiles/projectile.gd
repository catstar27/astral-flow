extends Polygon2D
class_name Projectile
## A projectile which is created by an ability

## Ability this is linked to
var ability: Ability = null

## Shoots the projectile at target location
func shoot(_destination: Vector2)->void:
	await get_tree().create_timer(.1).timeout
	queue_free()
