extends Interactive
class_name TravelPoint

@export var new_map: String

func _interact_extra(character: Character)->void:
	if character is Player:
		EventBus.broadcast("LOAD_MAP", new_map)
