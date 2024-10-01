extends Node2D
class_name SelectionCursor

@onready var sprite: Sprite2D = %Sprite
@onready var selection_area: Area2D = %SelectionArea
@export var tint: Color = Color.AQUA
var selected: Node2D = null
var hovering: Node2D = null
var moving: bool = false

func _ready() -> void:
	GlobalRes.hud = %HUD
	update_color()

func update_color()->void:
	sprite.modulate = tint

func _physics_process(_delta: float) -> void:
	var move_dir: Vector2i = Vector2i.ZERO
	if Input.is_action_pressed("left"):
		move_dir += Vector2i.LEFT
	if Input.is_action_pressed("right"):
		move_dir += Vector2i.RIGHT
	if Input.is_action_pressed("up"):
		move_dir += Vector2i.UP
	if Input.is_action_pressed("down"):
		move_dir += Vector2i.DOWN
	if !moving && move_dir != Vector2i.ZERO:
		move(move_dir)
	if Input.is_action_just_released("interact"):
		select(position)

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
			selected.move(pos)
	else:
		if selected is Character && hovering is Interactive:
			selected.call_deferred("interact", hovering)
		if hovering is Character:
			selected = hovering
			selected.call_deferred("select")

func _selection_area_entered(body: Node2D) -> void:
	hovering = body

func _selection_area_exited(body: Node2D) -> void:
	if hovering == body:
		hovering = null
