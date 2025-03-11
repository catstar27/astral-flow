@tool
extends Interactive
class_name InteractivePointLight
## Interactive that casts light around itself and can be toggled

@onready var light: PointLight2D = %Light ## Light node
var light_visible: bool = true ## Whether the light is visible

func _interact_extra(_character: Character)->void:
	if light_visible:
		disable_light()
	else:
		enable_light()
	light_visible = !light_visible

## Disables the light
func disable_light()->void:
	light.hide()

## Enables the light
func enable_light()->void:
	light.show()
