extends Ability

var status: Utility.Status

func _ready() -> void:
	status = Utility.Status.new()
	status.stat_mods["defense"] = 2
	status.id = "BLOCKING"
	status.display_name = "Blocking"
	status.status_color = Color.WEB_GRAY

func activate(destination: Vector2)->void:
	inflict_status(get_target(destination), status)
	activated.emit()
