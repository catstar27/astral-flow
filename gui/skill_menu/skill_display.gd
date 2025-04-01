@tool
extends Button
class_name SkillDisplay
## GUI element that displays the name and details of a skill

@export_multiline var display_name: String: ## Name for this skill
	set(new_name):
		display_name = new_name
		%NameLabel.text = new_name
		custom_minimum_size = $VBoxContainer.size + Vector2.ONE*12
		reset_size()
@export var effects: Array[SkillEffect]: ## Array of all effects granted by this skill
	set(arr):
		effects = arr
		add_effect_buttons()
@export var abilities: Array[Ability]: ## Array of abilities granted by this skill
	set(arr):
		abilities = arr
		add_ability_buttons()
@onready var effects_container: GridContainer = %EffectsContainer ## Container for skill effects
@onready var ability_container: GridContainer = %AbilitiesContainer ## Container for skill abilities
var ability_button_scn: PackedScene = preload("uid://bl1ksh3itp2fl") ## Scene for ability buttons
var effect_button_scn: PackedScene = preload("uid://cy6pdh0hesumj") ## Scene for effect buttons

## Adds an informational button for each effect
func add_effect_buttons()->void:
	for button in %EffectsContainer.get_children():
		if button is Button:
			button.queue_free()
	if effects.size() == 0:
		%EffectsContainer.get_child(0).show()
	else:
		%EffectsContainer.get_child(0).hide()
	for effect in effects:
		if effect == null:
			continue
		var new_button: SkillEffectButton = effect_button_scn.instantiate()
		new_button.set_effect(effect)
		%EffectsContainer.add_child(new_button)
		new_button.owner = self

## Adds an informational button for each ability
func add_ability_buttons()->void:
	for button in %AbilitiesContainer.get_children():
		if button is Button:
			button.queue_free()
	if abilities.size() == 0:
		%AbilitiesContainer.get_child(0).show()
	else:
		%AbilitiesContainer.get_child(0).hide()
	for ability in abilities:
		if ability == null:
			continue
		var new_button: AbilityButton = ability_button_scn.instantiate()
		new_button.pressed.disconnect(new_button._on_pressed)
		new_button.set_ability(ability)
		%AbilitiesContainer.add_child(new_button)
		new_button.owner = self
