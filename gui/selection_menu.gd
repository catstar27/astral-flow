extends PanelContainer
class_name SelectionMenu
## Menu for performing different actions with the selection cursor

const ability_button_scn: PackedScene = preload("uid://cavlvpuhv8qc7") ## Scene for resource button holding ability
var selected: Character = null ## Character that is acting
var target: Node2D = null ## Node this is analyzing
var abilities_shown: bool = false ## Whether the second part of the menu showing abilities is active
var is_open: bool = false ## Whether the menu is open
signal opened ## Emitted when opened
signal closed ## Emitted when closed

func _ready() -> void:
	EventBus.subscribe("SHOW_SELECTION_MENU", self, "open")
	EventBus.subscribe("DIALOGUE_ENTERED", self, "close_no_action")
	close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back") && is_open:
		get_viewport().set_input_as_handled()
		if abilities_shown:
			close_ability_container()
		else:
			close_no_action()

## Sets the menu position
func reset_pos()->void:
	position.x = (get_viewport_rect().size.x/2)+36
	position.y = (get_viewport_rect().size.y/2)-size.y/2

## Opens the menu
func open(data: Array)->void:
	target = data[0]
	selected = data[1]
	var valid_actions: Array[Button] = []
	if target == null && selected != null:
		%Move.show()
		valid_actions.append(%Move)
	elif target is Character && target != null:
		if !target.hostile_to_player && target.alive && selected != null && selected != target:
			%Interact.show()
			valid_actions.append(%Interact)
		if !target.alive && selected != null && selected != target:
			%Loot.show()
			valid_actions.append(%Loot)
		%Sheet.show()
		valid_actions.append(%Sheet)
		if target.is_in_group("PartyMember") && target.alive && selected != target:
			%Select.show()
			valid_actions.append(%Select)
		if selected == target && selected != null:
			%Deselect.show()
			valid_actions.append(%Deselect)
		if selected != null:
			check_abilities()
			if %Ability.visible:
				valid_actions.append(%Ability)
		if !target.alive && selected != null && selected != target:
			%Move.show()
			valid_actions.append(%Move)
	elif target is Interactive && target != null && selected != null:
		%Interact.show()
		valid_actions.append(%Interact)
		check_abilities()
		if %Ability.visible:
			valid_actions.append(%Ability)
	if valid_actions.is_empty():
		close_no_action()
		return
	elif valid_actions.size() == 1 && valid_actions[0] != %Ability:
		EventBus.broadcast("SELECTION_CURSOR_ACTION", valid_actions[0].name)
		if valid_actions[0] == %Sheet:
			EventBus.broadcast("SELECTION_CURSOR_ACTION", "")
		close()
		return
	%Divider.hide()
	%ScrollContainer.hide()
	reset_size()
	await get_tree().process_frame
	show()
	reset_pos()
	valid_actions[0].grab_focus()
	is_open = true
	opened.emit()

## Closes the menu
func close()->void:
	if abilities_shown:
		close_ability_container()
	if selected != null:
		selected.deselect_ability()
	target = null
	selected = null
	for button in %ButtonsContainer.get_children():
		button.hide()
	hide()
	for ability_button in %AbilityContainer.get_children():
		ability_button.queue_free()
	is_open = false
	closed.emit()

## Checks if there are valid abilities to use on the target, populating the list and showing the option if so
func check_abilities()->void:
	var valid_ability_list: Array[Ability] = []
	for ability in selected.abilities:
		if ability.is_target_valid(target) && ability.is_tile_valid(target.position):
			valid_ability_list.append(ability)
	if valid_ability_list.is_empty():
		%Ability.hide()
	else:
		%Ability.show()
		for ability in valid_ability_list:
			var new_ability_button: ResourceButton = ability_button_scn.instantiate()
			new_ability_button.resource = ability
			new_ability_button.icon = ability.icon
			new_ability_button.pressed_resource.connect(ability_pressed)
			new_ability_button.focused_resource.connect(ability_hovered)
			%AbilityContainer.add_child(new_ability_button)

## Opens the ability list
func open_ability_container()->void:
	%ScrollContainer.show()
	%Divider.show()
	for button in %ButtonsContainer.get_children():
		button.disabled = true
		button.focus_mode = FocusMode.FOCUS_NONE
	%AbilityContainer.get_child(0).grab_focus()
	reset_size()
	reset_pos()
	abilities_shown = true

## Closes the ability list
func close_ability_container()->void:
	if selected != null:
		selected.deselect_ability()
	%Divider.hide()
	%ScrollContainer.hide()
	for button in %ButtonsContainer.get_children():
		button.disabled = false
		button.focus_mode = FocusMode.FOCUS_ALL
	%Ability.grab_focus()
	reset_size()
	reset_pos()
	abilities_shown = false

func _on_interact_pressed() -> void:
	EventBus.broadcast("SELECTION_CURSOR_ACTION", "Interact")
	close()

func _on_loot_pressed() -> void:
	EventBus.broadcast("SELECTION_CURSOR_ACTION", "Loot")
	close()

func _on_sheet_pressed() -> void:
	EventBus.broadcast("SELECTION_CURSOR_ACTION", "Sheet")

func _on_select_pressed() -> void:
	EventBus.broadcast("SELECTION_CURSOR_ACTION", "Select")
	close()

func _on_deselect_pressed() -> void:
	EventBus.broadcast("SELECTION_CURSOR_ACTION", "Deselect")
	close()

func _on_ability_pressed() -> void:
	open_ability_container()

func _on_move_pressed() -> void:
	EventBus.broadcast("SELECTION_CURSOR_ACTION", "Move")
	close()

func ability_hovered(ability: Ability)->void:
	selected.select_ability(ability)

func ability_pressed(ability: Ability)->void:
	selected.select_ability(ability)
	EventBus.broadcast("SELECTION_CURSOR_ACTION", "Ability:"+ability.display_name)

## Closes the menu without doing anything
func close_no_action()->void:
	if is_open:
		EventBus.broadcast("SELECTION_CURSOR_ACTION", "")
		close()
