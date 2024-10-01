extends Control

@onready var player: Player = get_parent()
@onready var ability_list: VBoxContainer = %AbilityList
@onready var ability_button_scn: PackedScene = preload("res://misc/ability_button.tscn")

func _add_ability(ability: Ability):
	var new_button: AbilityButton = ability_button_scn.instantiate()
	new_button.ability = ability
	new_button.player = player
	ability_list.add_child(new_button)
