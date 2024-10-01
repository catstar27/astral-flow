extends RigidBody2D
class_name Interactive

func _interact_area_entered(body: Node2D) -> void:
	if body is Character:
		body.call_deferred("_enter_interactive_area", self)

func _interact_area_exited(body: Node2D) -> void:
	if body is Character:
		body.call_deferred("_exit_interactive_area")
