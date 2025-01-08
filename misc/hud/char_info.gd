extends Control
class_name CharInfo

@onready var ability_list: VBoxContainer = %AbilityList
@onready var hp_label: Label = %HP
@onready var ap_label: Label = %AP
@onready var mp_label: Label = %MP
@onready var end_turn_button: Button = %EndTurn
@onready var info_container: VBoxContainer = %Info
@onready var menu_button: ControlDisplayButton = %MenuButton
@export var ability_buttons: Array[AbilityButton]
var buttons_used: Array[bool] = [false, false, false, false, false, false, false, false, false, false]
enum states{closed, open, suspended}
var character: Character = null
var abilities: Array[Ability] = []
var state: states = states.closed
var changing_state: bool = false

func _ready() -> void:
	menu_button.disabled = true
	EventBus.subscribe("ABILITY_BUTTON_PRESSED", self, "suspend_menu")

func toggle_menu()->void:
	if state != states.closed:
		close_menu()
	else:
		open_menu()

func open_menu()->void:
	if state != states.closed || changing_state:
		return
	changing_state = true
	for i in range(0, 10):
		ability_buttons[i].disabled = !buttons_used[i]
	state = states.open
	menu_button.text = "←"
	modulate = Color(1,1,1,1)
	info_container.show()
	await create_tween().tween_property(info_container, "position", Vector2(0, info_container.position.y), .5).finished
	EventBus.broadcast(EventBus.Event.new("DEACTIVATE_SELECTION", "NULLDATA"))
	if ability_buttons[0].ability != null:
		ability_buttons[0].grab_focus()
	changing_state = false

func close_menu()->void:
	if state == states.closed || changing_state:
		return
	changing_state = true
	for button in ability_buttons:
		button.disabled = true
	var activate_selection: bool = true
	if state == states.suspended:
		activate_selection = false
	state = states.closed
	menu_button.text = "→"
	if activate_selection:
		EventBus.broadcast(EventBus.Event.new("ACTIVATE_SELECTION", "NULLDATA"))
	await create_tween().tween_property(info_container, "position", Vector2(-90, info_container.position.y), .5).finished
	modulate = Color(1,1,1,1)
	info_container.hide()
	changing_state = false

func suspend_menu(_ability)->void:
	if state == states.suspended || changing_state:
		return
	changing_state = true
	state = states.suspended
	await create_tween().tween_property(self, "modulate", Color(1,1,1,.5), .1).finished
	get_window().gui_release_focus()
	EventBus.broadcast(EventBus.Event.new("ACTIVATE_SELECTION", "NULLDATA"))
	changing_state = false

func unsuspend_menu()->void:
	if state != states.suspended || changing_state:
		return
	changing_state = true
	state = states.open
	await create_tween().tween_property(self, "modulate", Color(1,1,1,1), .1).finished
	EventBus.broadcast(EventBus.Event.new("DEACTIVATE_SELECTION", "NULLDATA"))
	if ability_buttons[0].ability != null:
		ability_buttons[0].grab_focus()
	changing_state = false

func enable_end_turn()->void:
	end_turn_button.disabled = false
	end_turn_button.focus_mode = Control.FOCUS_ALL
	set_first_last_buttons()

func disable_end_turn()->void:
	end_turn_button.disabled = true
	end_turn_button.focus_mode = Control.FOCUS_NONE
	set_first_last_buttons()

func set_first_last_buttons()->void:
	if end_turn_button.disabled:
		ability_buttons[0].focus_previous = ability_buttons[abilities.size()-1].get_path()
		ability_buttons[0].focus_neighbor_top = ability_buttons[abilities.size()-1].get_path()
		ability_buttons[abilities.size()-1].focus_next = ability_buttons[0].get_path()
		ability_buttons[abilities.size()-1].focus_neighbor_bottom = ability_buttons[0].get_path()
		print(abilities.size()-1)
	else:
		ability_buttons[0].focus_previous = end_turn_button.get_path()
		ability_buttons[0].focus_neighbor_top = end_turn_button.get_path()
		ability_buttons[abilities.size()-1].focus_next = end_turn_button.get_path()
		ability_buttons[abilities.size()-1].focus_neighbor_bottom = end_turn_button.get_path()

func add_ability(index: int, ability: Ability)->AbilityButton:
	var button: AbilityButton = ability_buttons[index]
	var prev: AbilityButton = null
	if index > 0:
		prev = ability_buttons[index-1]
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	button.set_ability(ability)
	if prev != null:
		button.focus_previous = prev.get_path()
		button.focus_neighbor_top = prev.get_path()
		prev.focus_next = button.get_path()
		prev.focus_neighbor_bottom = button.get_path()
	return button

func clear_abilities()->void:
	abilities = []
	for button in ability_buttons:
		button.clear_ability()

func set_character(new_char: Character)->void:
	if new_char == null:
		if character != null:
			character.stats_changed.disconnect(update_labels)
			end_turn_button.pressed.disconnect(character.end_turn)
			character.abilities_changed.disconnect(update_abilities)
			character.combat_entered.disconnect(enable_end_turn)
			character.combat_exited.disconnect(disable_end_turn)
			character.ability_deselected.disconnect(unsuspend_menu)
			character = null
			menu_button.disabled = true
			create_tween().tween_property(menu_button, "modulate", Color(1,1,1,.5), .1)
		return
	if new_char == character:
		return
	elif character != null:
		end_turn_button.pressed.disconnect(character.end_self_turn)
	menu_button.disabled = false
	create_tween().tween_property(menu_button, "modulate", Color(1,1,1,1), .1)
	disable_end_turn()
	character = new_char
	abilities = []
	character.stats_changed.connect(update_labels)
	update_labels()
	end_turn_button.pressed.connect(character.end_turn)
	character.abilities_changed.connect(update_abilities)
	character.combat_entered.connect(enable_end_turn)
	character.combat_exited.connect(disable_end_turn)
	character.ability_deselected.connect(unsuspend_menu)
	update_abilities()
	if character.in_combat:
		enable_end_turn()
	else:
		disable_end_turn()

func update_labels()->void:
	hp_label.text = "HP: "+str(character.cur_hp)
	ap_label.text = "AP: "+str(character.cur_ap)
	mp_label.text = "MP: "+str(character.cur_mp)

func update_abilities()->void:
	clear_abilities()
	for i in range(0, 10):
		buttons_used[i] = false
	var index: int = 0
	for ability in character.get_abilities():
		if index > 9:
			break
		add_ability(index, ability)
		abilities.append(ability)
		buttons_used[index] = true
		index += 1
	set_first_last_buttons()
	while index < 10:
		buttons_used[index] = false
		ability_buttons[index].disabled = true
		ability_buttons[index].focus_mode = Control.FOCUS_NONE
		index += 1
