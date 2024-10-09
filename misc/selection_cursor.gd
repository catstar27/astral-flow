extends Node2D
class_name SelectionCursor

@onready var sprite: Sprite2D = %Sprite
@onready var selection_area: Area2D = %SelectionArea
@export var tint: Color = Color.AQUA
var selected: Node2D = null
var hovering: Node2D = null
var moving: bool = false
var move_dir: Vector2i = Vector2i.ZERO

func _ready() -> void:
	GlobalRes.update_var(%HUD)
	update_color()

func reset_move_dir()->void:
	move_dir = Vector2i.ZERO

func update_color()->void:
	sprite.modulate = tint

func _scale_float(num: float)->int:
	if num > 0:
		return 1
	if num < 0:
		return -1
	return 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("left") || event.is_action("right"):
		move_dir.x = _scale_float(Input.get_axis("left", "right"))
	if event.is_action("up") || event.is_action("down"):
		move_dir.y = _scale_float(Input.get_axis("up", "down"))
	if event.is_action_released("interact"):
		interact_on_pos(position)

func _physics_process(_delta: float) -> void:
	if !moving && move_dir != Vector2i.ZERO:
		move(move_dir)

func move(dir: Vector2i)->void:
	moving = true
	var cur_map_pos: Vector2i = GlobalRes.map.local_to_map(position)
	var new_pos: Vector2 = GlobalRes.map.map_to_local(dir+cur_map_pos)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", new_pos, .2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(move_stop)

func move_stop()->void:
	moving = false

func interact_on_pos(pos: Vector2i)->void:
	if selected is Ability:
		selected.user.activate_ability(selected, pos)
	elif hovering == null || hovering is GameMap:
		if selected is Character:
			selected.target_position = pos
			if selected.moving:
				await selected.move_interrupt
			selected.call_deferred("move")
	else:
		if selected is Character && hovering is Interactive:
			var hovering_select: Interactive = hovering
			selected.target_position = pos
			if selected.moving:
				await selected.move_interrupt
			selected.call_deferred("interact", hovering_select)
		if hovering is Character && selected == null:
			select(hovering)
			selected.call_deferred("select")

func select(node: Node)->void:
	selected = node

func _selection_area_entered(body: Node2D) -> void:
	if !body is GameMap:
		hovering = body

func _selection_area_exited(body: Node2D) -> void:
	if hovering == body:
		hovering = null
