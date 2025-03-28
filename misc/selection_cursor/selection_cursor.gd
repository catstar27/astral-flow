extends Node2D
class_name SelectionCursor
## Cursor that allows the player to view the map and select characters
##
## Can have one character selected at a time, and can make that character
## move, interact, activate abilities, etc.

@export var move_arrow_tex: Texture2D ## Texture of movement arrows
@onready var sprite: Sprite2D = %Sprite ## Sprite of the cursor
@onready var selection_area: Area2D = %SelectionArea ## Area which detects objects to select/interact
@onready var camera: Camera2D = %Camera ## Camera node, which is part of this
@onready var selection_marker: Node2D = %SelectionMarker ## The selection marker
var move_arrow_scn: PackedScene = preload("uid://dsp8lf7fyd2h7") ## Movement arrow scene
var selected: Character = null ## Character the cursor has selected
var hovering: Node2D = null ## Object the cursor is hovering over
var moving: bool = false ## Whether the cursor is moving
var move_dir: Vector2 = Vector2i.ZERO ## Direction to move in
var move_arrows: Array[Sprite2D] = [] ## Array of sprites making up the movement arrows
var deactivate_requests: int = 0 ## Number of sources attempting to deactivate the cursor; inactive if > 0
var block_deselect: bool = false ## Blocks the cursor from deselecting
signal move_stopped ## Emitted when the cursor stops moving

func _ready() -> void:
	update_color()
	EventBus.subscribe("DEACTIVATE_SELECTION", self, "deactivate")
	EventBus.subscribe("ACTIVATE_SELECTION", self, "activate")
	EventBus.subscribe("COMBAT_STARTED", self, "deselect")
	EventBus.subscribe("COMBAT_STARTED", self, "check_quick_info")
	EventBus.subscribe("ABILITY_BUTTON_PRESSED", self, "select_ability")
	EventBus.subscribe("GAMEPLAY_SETTINGS_CHANGED", self, "update_color")
	await get_tree().create_timer(1).timeout
	check_quick_info()

## Updates the color of the cursor and its markers
func update_color()->void:
	sprite.modulate = Settings.gameplay.selection_tint
	selection_marker.modulate = Settings.gameplay.selection_tint
	for move_arrow in move_arrows:
		move_arrow.modulate = sprite.modulate

## Takes a float and converts it into -1, 0, or 1
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
		act_on_pos(position)
	if event.is_action_pressed("clear"):
		if selected != null:
			if selected.selected_ability == null:
				deselect()

func _physics_process(_delta: float) -> void:
	if !moving && move_dir != Vector2.ZERO:
		move(move_dir)

#region Movement Arrow
## Makes a path of arrow pieces to display the projected path of movement
func update_move_arrows(character: Character)->void:
	if character == null || character.selected_ability != null:
		clear_move_arrows()
		return
	if NavMaster.is_pos_occupied(position) && position.distance_to(character.position) <= NavMaster.tile_size:
		clear_move_arrows()
		return
	var path: Array[Vector2] = NavMaster.request_nav_path(character.global_position, global_position)
	if path.size() <= 1:
		clear_move_arrows()
		return
	var ap_arr: Array[Array] = character.get_ap_for_path(path.size()-1, false)
	path.resize(ap_arr.size())
	var index: int = 0
	while index < path.size():
		if character != selected:
			return
		if character.in_combat && character.cur_ap == 0:
			break
		while move_arrows.size() <= index:
			var new_arrow: MoveArrow = move_arrow_scn.instantiate()
			new_arrow.self_modulate = Settings.gameplay.selection_tint
			move_arrows.append(new_arrow)
			add_child(new_arrow)
		if index == 0:
			move_arrows[index].position = path[index]
			move_arrows[index].draw_tail(path[index],path[index+1])
		else:
			move_arrows[index].position = path[index]
			if index < path.size()-1:
				move_arrows[index].draw_between(path[index-1], path[index+1])
			else:
				move_arrows[index].draw_head(path[index-1], path[index])
			if character.in_combat:
				if ap_arr[index-1][0] != ap_arr[index][0]:
					move_arrows[index].set_label(str(character.cur_ap-ap_arr[index][0]))
				else:
					move_arrows[index].set_label("...")
			else:
				move_arrows[index].set_label("")
		index += 1
	while index < move_arrows.size():
		move_arrows[index].hide()
		index += 1

## Deletes all movement arrow pieces
func clear_move_arrows()->void:
	for move_arrow in move_arrows:
		move_arrow.hide()
#endregion

#region Actions
## Activates the cursor, allowing it to move or act
func activate()->void:
	move_dir = Vector2.ZERO
	if deactivate_requests == 0:
		printerr("Attempted to activate selection cursor that was active")
		return
	deactivate_requests -= 1

## Deactivates the cursor, preventing it from doing anything
func deactivate()->void:
	move_dir = Vector2.ZERO
	deactivate_requests += 1

## Moves the cursor in the given direction
func move(dir: Vector2)->void:
	moving = true
	var new_pos: Vector2 = NavMaster.tile_size*dir+position
	if !NavMaster.is_in_bounds(new_pos) && NavMaster.is_in_bounds(position):
		pass
	else:
		if hovering != null && hovering is Character:
			EventBus.broadcast("HIDE_QUICK_INFO", "NULLDATA")
		var tween: Tween = create_tween()
		var time: float = .2
		if Input.is_action_pressed("shift"):
			time = .1
		await tween.tween_property(self, "position", new_pos, time).set_ease(Tween.EASE_IN_OUT).finished
		if NavMaster.is_in_bounds(position):
			update_move_arrows(selected)
	moving = false
	move_stopped.emit()
	check_quick_info()

## Performs an action at given position based on current state
func act_on_pos(pos: Vector2i)->void:
	if hovering is Player && selected == null:
		select(hovering)
	elif selected == null:
		return
	elif selected.selected_ability != null:
		selected.activate_ability(selected.selected_ability, pos)
	elif hovering == null || hovering is GameMap:
		selected.move(pos)
	elif hovering is Interactive || (hovering is Character && hovering != selected):
		await selected_interact(pos)

## Makes the selected character interact with the target
func selected_interact(pos: Vector2)->void:
	var cur_hover = hovering
	selected.move(pos)
	block_deselect = true
	while selected.state_machine.current_state.state_id != "IDLE":
		await selected.state_machine.state_changed
	selected.interact(cur_hover)
	block_deselect = false
#endregion

#region Selection
## Creates a marker to show a character is selected
func _place_marker()->void:
	remove_child(selection_marker)
	selected.add_child(selection_marker)

## Deletes the current marker
func _reclaim_marker()->void:
	selected.remove_child(selection_marker)
	add_child(selection_marker)

## Selects the given character
func select(character: Character)->void:
	if character.in_combat && !character.taking_turn:
		return
	if character != null && selected == character:
		return
	if block_deselect:
		return
	if selected != null:
		deselect()
	selected = character
	if selected != null:
		selected.call_deferred("select")
		selected.ended_turn.connect(deselect)
		selected.pos_changed.connect(update_move_arrows)
		selected.ability_selected.connect(check_quick_info)
		selected.ability_deselected.connect(check_quick_info)
		_place_marker()
	EventBus.broadcast("SELECTION_CHANGED",selected)

## Deselects the current character
func deselect(_node: Character = null)->void:
	if block_deselect:
		return
	clear_move_arrows()
	_reclaim_marker()
	if selected == null:
		return
	var prev_select: Character = selected
	selected = null
	prev_select.call_deferred("deselect")
	prev_select.ended_turn.disconnect(deselect)
	prev_select.pos_changed.disconnect(update_move_arrows)
	prev_select.ability_selected.disconnect(check_quick_info)
	prev_select.ability_deselected.disconnect(check_quick_info)
	EventBus.broadcast("SELECTION_CHANGED",selected)

func _selection_area_entered(body: Node2D) -> void:
	if !body is GameMap:
		hovering = body

func _selection_area_exited(body: Node2D) -> void:
	if hovering == body:
		hovering = null
		EventBus.broadcast("HIDE_QUICK_INFO", "NULLDATA")

func check_quick_info(_data = null) -> void:
	if moving:
		return
	if hovering != null && hovering is Character && hovering.in_combat:
		if selected == null:
			EventBus.broadcast("SHOW_QUICK_INFO", hovering)
		elif selected.state_machine.current_state.state_id == "IDLE" && selected.selected_ability == null:
			EventBus.broadcast("SHOW_QUICK_INFO", hovering)
		else:
			EventBus.broadcast("HIDE_QUICK_INFO", "NULLDATA")
	else:
		EventBus.broadcast("HIDE_QUICK_INFO", "NULLDATA")
#endregion
