extends Interactive
class_name InteractivePointLight

@onready var light: PointLight2D = %Light
var light_visible: bool = true

func _interacted(_character: Character)->void:
	if light_visible:
		disable_light()
	else:
		enable_light()
	light_visible = !light_visible

func disable_light()->void:
	light.hide()

func enable_light()->void:
	light.show()
