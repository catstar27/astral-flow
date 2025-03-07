extends Interactive
class_name TravelPoint
## An interactive that changes the map

enum exit_directions{ ## List of directions 
	up,
	down,
	left,
	right
}
@export var exit_direction: exit_directions ## The direction this puts the player in
@export var entrance_id: String ## ID of this entrance
@export var target_entrance_id: String ## ID of the entrance this leads to
@export var new_map: String ## File path of the map this leads to

func _interact_extra(character: Character)->void:
	if character is Player && !SaveLoad.loading && !SaveLoad.saving:
		EventBus.broadcast("LOAD_MAP_AT_ENTRANCE", [new_map, target_entrance_id])

## Returns the position this exits from
func get_exit_position()->Vector2:
	match exit_direction:
		exit_directions.up:
			return position+(Vector2.UP*NavMaster.tile_size)
		exit_directions.down:
			return position+(Vector2.DOWN*NavMaster.tile_size)
		exit_directions.left:
			return position+(Vector2.LEFT*NavMaster.tile_size)
		exit_directions.right:
			return position+(Vector2.RIGHT*NavMaster.tile_size)
		_:
			return position+(Vector2.UP*NavMaster.tile_size)
