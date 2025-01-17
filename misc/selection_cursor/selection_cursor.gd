extends Node2D
class_name SelectionCursor

@export var move_arrow_tex: Texture2D
@export var move_arrow_mat: CanvasItemMaterial
@onready var sprite: Sprite2D = %Sprite
@onready var selection_area: Area2D = %SelectionArea
var selection_marker_scene: PackedScene = preload("res://misc/selection_cursor/selection_marker.tscn")
var selected: Character = null
var hovering: Node2D = null
var moving: bool = false
var move_dir: Vector2 = Vector2i.ZERO
var marker: Node2D = null
var move_arrows: Array[Sprite2D] = []
var deactivate_requests: int = 0

func _ready() -> void:
	update_color()
	EventBus.subscribe("DEACTIVATE_SELECTION", self, "deactivate")
	EventBus.subscribe("ACTIVATE_SELECTION", self, "activate")
	EventBus.subscribe("COMBAT_STARTED", self, "deselect")
	EventBus.subscribe("ABILITY_BUTTON_PRESSED", self, "select_ability")
	EventBus.subscribe("GAMEPLAY_SETTINGS_CHANGED", self, "update_color")

func activate()->void:
	reset_move_dir()
	if deactivate_requests == 0:
		printerr("Attempted to activate selection cursor that was active")
		return
	deactivate_requests -= 1

func deactivate()->void:
	reset_move_dir()
	deactivate_requests += 1

func _create_marker()->void:
	marker = selection_marker_scene.instantiate()
	marker.modulate = Settings.gameplay.selection_tint
	selected.add_child(marker)

func _delete_marker()->void:
	if marker != null:
		marker.queue_free()

func reset_move_dir()->void:
	move_dir = Vector2.ZERO

func update_color()->void:
	sprite.modulate = Settings.gameplay.selection_tint

func _scale_float(num: float)->int:
	if num > 0:
		return 1
	if num < 0:
		return -1
	return 0

func _unhandled_input(event: InputEvent) -> void:
	if deactivate_requests > 0:
		return
	if event.is_action("left") || event.is_action("right"):
		move_dir.x = _scale_float(Input.get_axis("left", "right"))
	if event.is_action("up") || event.is_action("down"):
		move_dir.y = _scale_float(Input.get_axis("up", "down"))
	if event.is_action_pressed("interact"):
		interact_on_pos(position)
	if event.is_action_pressed("clear"):
		if selected != null:
			if selected.selected_ability == null:
				deselect()
	if event.is_action_pressed("info") && selected != null:
		update_move_arrows(selected)
	if event.is_action_released("info"):
		clear_move_arrows()

func _physics_process(_delta: float) -> void:
	if !moving && move_dir != Vector2.ZERO:
		move(move_dir)

func clear_move_arrows()->void:
	while move_arrows != []:
		move_arrows.pop_back().queue_free()

func update_move_arrows(character: Character)->void:
	clear_move_arrows()
	if Input.is_action_pressed("info"):
		var path: Array[Vector2] = NavMaster.request_nav_path(character.global_position, global_position)
		if path.size() == 1 || character.global_position == global_position:
			return
		for index in range(1, path.size()):
			if character != selected:
				break
			var new_arrow: Sprite2D = Sprite2D.new()
			move_arrows.append(new_arrow)
			new_arrow.texture = move_arrow_tex
			new_arrow.hframes = 3
			new_arrow.position = path[index]
			new_arrow.scale = Vector2.ONE*4
			new_arrow.material = move_arrow_mat
			new_arrow.look_at(path[index-1])
			if index > 1 && move_arrows[index-2].rotation != new_arrow.rotation:
				move_arrows[index-2].frame = 1
				var dir_enter: Vector2 = -(path[index-1]-path[index-2]).normalized()
				var dir_exit: Vector2 = -(path[index-1]-path[index]).normalized()
				move_arrows[index-2].rotation = 0
				if (dir_exit == Vector2.DOWN || dir_enter == Vector2.DOWN) && (dir_exit == Vector2.LEFT || dir_enter == Vector2.LEFT):
					move_arrows[index-2].rotation = PI
				elif dir_exit == Vector2.DOWN || dir_enter == Vector2.DOWN:
					move_arrows[index-2].rotation = PI/2
				elif dir_exit == Vector2.LEFT || dir_enter == Vector2.LEFT:
					move_arrows[index-2].rotation = -PI/2
			if index == path.size()-1:
				new_arrow.rotation -= PI
				new_arrow.frame = 2
			get_parent().add_child(new_arrow)

func move(dir: Vector2)->void:
	moving = true
	var new_pos: Vector2 = NavMaster.tile_size*dir+position
	if !NavMaster.is_in_bounds(new_pos):
		move_stop(false)
		return
	var tween: Tween = create_tween()
	var time: float = .2
	if Input.is_action_pressed("shift"):
		time = .1
	tween.tween_property(self, "position", new_pos, time).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(move_stop)

func move_stop(in_bounds: bool = true)->void:
	moving = false
	if selected is Character && in_bounds:
		update_move_arrows(selected)

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
		selected.pos_changed.connect(update_move_arrows)
	if selected != null:
		_create_marker()
	EventBus.broadcast("SELECTION_CHANGED",selected)

func deselect(_node: Character = null)->void:
	clear_move_arrows()
	_delete_marker()
	if selected == null:
		return
	var prev_select: Character = selected
	selected = null
	prev_select.call_deferred("deselect")
	prev_select.ended_turn.disconnect(deselect)
	prev_select.pos_changed.disconnect(update_move_arrows)
	EventBus.broadcast("SELECTION_CHANGED",selected)

func _selection_area_entered(body: Node2D) -> void:
	if !body is GameMap:
		hovering = body

func _selection_area_exited(body: Node2D) -> void:
	if hovering == body:
		hovering = null

func save_data(file: FileAccess)->void:
	file.store_var(position)

func load_data(file: FileAccess)->void:
	position = file.get_var()
