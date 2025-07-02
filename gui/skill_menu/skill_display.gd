@tool
extends Button
class_name SkillDisplay
## GUI element that displays the name and details of a skill

const button_theme: Theme = preload("uid://dehvu01nlqvsf") ## Theme for ability buttons
const ability_button_scn: PackedScene = preload("uid://bl1ksh3itp2fl") ## Scene for ability buttons
const effect_button_scn: PackedScene = preload("uid://cy6pdh0hesumj") ## Scene for effect buttons
@export var skill: Skill: ## Skill to display
	set(new_skill):
		skill = new_skill
		if skill != null:
			%NameLabel.text = skill.display_name
		else:
			%NameLabel.text = "Name Here"
		custom_minimum_size = $VBoxContainer.size + Vector2.ONE*12
		reset_size()
		add_effect_buttons()
		add_ability_buttons()
@onready var effects_container: GridContainer = %EffectsContainer ## Container for skill effects
@onready var ability_container: GridContainer = %AbilitiesContainer ## Container for skill abilities

## Adds an informational button for each effect
func add_effect_buttons()->void:
	for button in %EffectsContainer.get_children():
		if button is Button:
			button.queue_free()
	if skill.skill_effects.size() == 0:
		%EffectsContainer.get_child(0).show()
	else:
		%EffectsContainer.get_child(0).hide()
	for effect in skill.skill_effects:
		if effect == null:
			continue
		var new_button: SkillEffectButton = effect_button_scn.instantiate()
		new_button.set_effect(effect)
		new_button.theme = button_theme
		%EffectsContainer.add_child(new_button)
		new_button.owner = self

## Adds an informational button for each ability
func add_ability_buttons()->void:
	for button in %AbilitiesContainer.get_children():
		if button is Button:
			button.queue_free()
	if skill.abilities.size() == 0:
		%AbilitiesContainer.get_child(0).show()
	else:
		%AbilitiesContainer.get_child(0).hide()
	for ability in skill.abilities:
		if ability == null:
			continue
		var new_button: AbilityButton = ability_button_scn.instantiate()
		new_button.pressed.disconnect(new_button._on_pressed)
		new_button.set_ability(ability)
		new_button.theme = button_theme
		%AbilitiesContainer.add_child(new_button)
		new_button.owner = self
