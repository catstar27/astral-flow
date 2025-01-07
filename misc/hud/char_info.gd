extends VBoxContainer
class_name CharInfo

@onready var ability_list: VBoxContainer = %AbilityList
@onready var hp_label: Label = %HP
@onready var ap_label: Label = %AP
@onready var mp_label: Label = %MP
@onready var end_turn_button: Button = %EndTurn
@export var ability_buttons: Array[AbilityButton]
var character: Character = null
var abilities: Array[Ability] = []
var open: bool = false

func open_menu()->void:
	if open:
		return
	open = true
	show()
	await create_tween().tween_property(self, "position", Vector2(0, position.y), .5).finished
	if ability_buttons[0].ability != null:
		ability_buttons[0].grab_focus()

func close_menu()->void:
	if !open:
		return
	open = false
	await create_tween().tween_property(self, "position", Vector2(-100, position.y), .5).finished
	hide()

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
		button.focus_neighbor_bottom = prev.get_path()
		prev.focus_next = button.get_path()
		prev.focus_neighbor_top = button.get_path()
	return button

func clear_abilities()->void:
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
			character = null
		return
	if new_char == character:
		return
	elif character != null:
		end_turn_button.pressed.disconnect(character.end_self_turn)
	disable_end_turn()
	character = new_char
	abilities = []
	character.stats_changed.connect(update_labels)
	update_labels()
	end_turn_button.pressed.connect(character.end_turn)
	character.abilities_changed.connect(update_abilities)
	character.combat_entered.connect(enable_end_turn)
	character.combat_exited.connect(disable_end_turn)
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
	var index: int = 0
	for ability in character.get_abilities():
		if index > 9:
			break
		add_ability(index, ability)
		abilities.append(ability)
		index += 1
	set_first_last_buttons()
	while index < 10:
		ability_buttons[index].disabled = true
		ability_buttons[index].focus_mode = Control.FOCUS_NONE
		index += 1
