extends NPCTask
class_name WanderTask
## A task that makes an npc wander around a home point a number of tiles within a set maximum

@export var wander_home: Vector2 ## Home point to determine wander range
@export var wander_max_tiles: Vector2i = Vector2i.ZERO ## Number of tiles away from home this can wander

func task()->void:
	await wander()

## Makes the user wander within an area around a set home
func wander()->void:
	var max_distance: Vector2 = wander_max_tiles*NavMaster.tile_size
	var x_min: float = wander_home.x - max_distance.x
	var x_max: float = wander_home.x + max_distance.x
	var y_min: float = wander_home.y - max_distance.y
	var y_max: float = wander_home.y + max_distance.y
	var wander_pos: Vector2 = Vector2(randf_range(x_min,x_max),randf_range(y_min,y_max))
	while paused:
		await unpause
	user.move_order.emit(wander_pos)
	while user.state_machine.current_state.state_id != "IDLE":
		await user.state_machine.state_changed
