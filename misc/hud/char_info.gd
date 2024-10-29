extends VBoxContainer
class_name CharInfo

@onready var ability_list: VBoxContainer = %AbilityList
@onready var ability_button_scn: PackedScene = preload("res://misc/hud/ability_button.tscn")
@onready var hp_label: Label = %HP
@onready var ap_label: Label = %AP
@onready var mp_label: Label = %MP
@onready var end_turn_button: Button = %EndTurn
var character: Character = null
var abilities: Array[Ability] = []

func add_ability(ability: Ability)->void:
	var new_button: AbilityButton = ability_button_scn.instantiate()
	new_button.ability = ability
	ability_list.add_child(new_button)

func set_character(new_char: Character)->void:
	if new_char == character:
		for ability in character.get_abilities():
			if ability not in abilities:
				add_ability(ability)
				abilities.append(ability)
		return
	elif character != null:
		end_turn_button.pressed.disconnect(character.end_self_turn)
	character = new_char
	abilities = []
	character.stats_changed.connect(update_labels)
	update_labels()
	end_turn_button.pressed.connect(character.end_turn)
	for ability in character.get_abilities():
		add_ability(ability)
		abilities.append(ability)

func update_labels()->void:
	hp_label.text = "HP: "+str(character.cur_hp)
	ap_label.text = "AP: "+str(character.cur_ap)
	mp_label.text = "MP: "+str(character.cur_mp)
