extends Interactive
class_name InteractivePointLight

@onready var light: PointLight2D = %Light

func disable_light()->void:
	light.hide()

func enable_light()->void:
	light.show()
