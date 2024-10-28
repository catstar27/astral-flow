extends VBoxContainer
class_name CharInfo

@onready var ability_list: VBoxContainer = %AbilityList
@onready var ability_button_scn: PackedScene = preload("res://misc/hud/ability_button.tscn")
@onready var hp_label: Label = %HP
@onready var ap_label: Label = %AP
@onready var mp_label: Label = %MP
var character: Character = null

func add_ability(ability: Ability)->void:
	var new_button: AbilityButton = ability_button_scn.instantiate()
	new_button.ability = ability
	ability_list.add_child(new_button)

func set_character(new_char: Character)->void:
	if new_char == character:
		return
	character = new_char
	character.stats_changed.connect(update_labels)
	update_labels()
	for ability in character.get_abilities():
		add_ability(ability)

func update_labels()->void:
	hp_label.text = "HP: "+str(character.cur_hp)
	ap_label.text = "AP: "+str(character.cur_ap)
	mp_label.text = "MP: "+str(character.cur_mp)
