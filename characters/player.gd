extends Character
class_name Player

@onready var hud: Control = %HUD

func _ready() -> void:
	populate_ability_list()

func _physics_process(delta: float) -> void:
	var move_dir: Vector2 = Vector2.ZERO
	move_dir.x = Input.get_axis("left", "right")
	move_dir.y = Input.get_axis("up", "down")
	velocity = move_dir.normalized()*delta*move_speed*1000
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_released("interact") and interactive_in_range != null:
		interact()

func populate_ability_list()->void:
	for child in get_children():
		if child is Ability:
			hud._add_ability(child)
