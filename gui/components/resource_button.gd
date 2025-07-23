extends Button
class_name ResourceButton
## Button that holds a resource and can emit that resource with a signal when pressed

@export var resource: Resource ## Resource this button tracks

signal pressed_resource(resource: Resource) ## Emits with the tracked resource when pressed
signal focused_resource(resource: Resource) ## Emits the tracked resource when focused

func _on_pressed() -> void:
	pressed_resource.emit(resource)

func _on_focus_entered() -> void:
	focused_resource.emit(resource)
