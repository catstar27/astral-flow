extends Button
class_name ResourceButton
## Button that holds a resource and can emit that resource with a signal when pressed

@export var resource: Resource ## Resource this button tracks

signal pressed_resource(resource: Resource) ## Emits with the tracked resource when pressed

func _on_pressed() -> void:
	pressed_resource.emit(resource)
