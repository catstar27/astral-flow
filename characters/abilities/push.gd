extends Ability

var status: Utility.Status

func push(data: Array)->void:
	var target: Node2D = data[0]
	var prev_pos: Vector2 = target.global_position
	var destination: Vector2 = target.global_position+data[1]
	var path: Array[Vector2] = NavMaster.request_nav_path(prev_pos, destination, false)
	path.pop_front()
	if path.size() == 1:
		EventBus.broadcast("TILE_OCCUPIED", path.front())
		await create_tween().tween_property(target, "position", path.front(), .1).finished
		EventBus.broadcast("TILE_UNOCCUPIED", prev_pos)

func _ready() -> void:
	status = Utility.Status.new()
	status.action = push
	status.id = "PUSHED"
	status.display_name = "Pushed"
	status.time_choice = status.time_options.instant
	status.status_color = Color.LIGHT_BLUE

func activate(destination: Vector2)->void:
	play_sound()
	status.action_args = [get_target(destination), destination-user.global_position]
	inflict_status(get_target(destination), status)
	activated.emit()
