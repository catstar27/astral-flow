extends Node2D
class_name SelectionCursor

@onready var sprite: Sprite2D = %Sprite
@onready var selection_area: Area2D = %SelectionArea
@onready var selection_marker_scene: PackedScene = preload("res://misc/selection_marker.tscn")
var selected: Character = null
var hovering: Node2D = null
var moving: bool = false
var move_dir: Vector2 = Vector2i.ZERO
var marker: Node2D = null

func _ready() -> void:
	update_color()
	EventBus.subscribe("COMBAT_STARTED", self, "deselect")
	EventBus.subscribe("ABILITY_BUTTON_PRESSED", self, "select_ability")

func _create_marker()->void:
	marker = selection_marker_scene.instantiate()
	marker.modulate = Settings.selection_tint
	selected.add_child(marker)

func _delete_marker()->void:
	if marker != null:
		marker.queue_free()

func reset_move_dir()->void:
	move_dir = Vector2.ZERO

func update_color()->void:
	sprite.modulate = Settings.selection_tint

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
	if event.is_action_pressed("interact"):
		interact_on_pos(position)
	if event.is_action_pressed("clear"):
		deselect()

func _physics_process(_delta: float) -> void:
	if !moving && move_dir != Vector2.ZERO:
		move(move_dir)

func move(dir: Vector2)->void:
	moving = true
	var new_pos: Vector2 = Settings.tile_size*dir+position
	if !NavMaster.is_in_bounds(new_pos):
		move_stop()
		return
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", new_pos, .2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(move_stop)

func move_stop()->void:
	moving = false

func interact_on_pos(pos: Vector2i)->void:
	if hovering is Player && selected == null:
		select(hovering)
	elif selected == null:
		return
	elif selected.selected_ability != null:
		var ability: Ability = selected.selected_ability
		selected.emit_signal("ability_order", [ability, pos])
	elif hovering == null || hovering is GameMap:
		selected.emit_signal("move_order", pos)
	elif hovering is Interactive || hovering is NPC:
		var cur_hover = hovering
		selected.emit_signal("move_order", pos)
		while selected.state_machine.current_state.state_id != "IDLE":
			await selected.state_machine.state_changed
		selected.emit_signal("interact_order", cur_hover)

func select_ability(ability: Ability)->void:
	select(ability.user)

func select(node: Character)->void:
	if node is Character && node.in_combat && !node.taking_turn:
		return
	if node != null && selected == node:
		return
	if selected != null:
		deselect()
	selected = node
	if selected is Character:
		selected.call_deferred("select")
		selected.ended_turn.connect(deselect)
	if selected != null:
		_create_marker()
	EventBus.broadcast(EventBus.Event.new("SELECTION_CHANGED",selected))

func deselect(_node: Character = null)->void:
	_delete_marker()
	if selected == null:
		return
	var prev_select: Character = selected
	selected = null
	if prev_select is Character:
		prev_select.call_deferred("deselect")
		prev_select.ended_turn.disconnect(deselect)
	EventBus.broadcast(EventBus.Event.new("SELECTION_CHANGED",selected))

func _selection_area_entered(body: Node2D) -> void:
	if !body is GameMap:
		hovering = body

func _selection_area_exited(body: Node2D) -> void:
	if hovering == body:
		hovering = null
