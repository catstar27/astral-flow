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

func update_color()->void:
	sprite.modulate = tint

func _unhandled_input(event: InputEvent) -> void:
	if Dialogic.Text.is_textbox_visible():
		return
	if event.is_action_pressed("left"):
		move_dir += Vector2i.LEFT
	if event.is_action_pressed("right"):
		move_dir += Vector2i.RIGHT
	if event.is_action_pressed("up"):
		move_dir += Vector2i.UP
	if event.is_action_pressed("down"):
		move_dir += Vector2i.DOWN
	if Input.is_action_just_released("interact"):
		select(position)

func _physics_process(delta: float) -> void:
	if !moving && move_dir != Vector2i.ZERO:
		var prev_move: Vector2i = move_dir
		move_dir = Vector2i.ZERO
		move(prev_move)

func move(move_dir: Vector2i)->void:
	moving = true
	var cur_map_pos: Vector2i = GlobalRes.map.local_to_map(position)
	var new_pos: Vector2 = GlobalRes.map.map_to_local(move_dir+cur_map_pos)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", new_pos, .2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(move_stop)

func move_stop()->void:
	moving = false

func select(pos: Vector2i)->void:
	if hovering == null:
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
		if hovering is Character:
			selected = hovering
			selected.call_deferred("select")

func _selection_area_entered(body: Node2D) -> void:
	hovering = body

func _selection_area_exited(body: Node2D) -> void:
	if hovering == body:
		hovering = null
