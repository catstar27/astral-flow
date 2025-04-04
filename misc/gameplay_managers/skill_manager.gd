@tool
extends Node
class_name SkillManager
## Manages allocation of skills to characters

@export var skill_list: Array[Skill]: ## List of skills
	set(list):
		skill_list = list
		populate_dictionary()
@export_storage var skill_dictionary: Dictionary[String, Skill] ## Dictionary linking skills and their ids

func _ready() -> void:
	if not Engine.is_editor_hint():
		EventBus.subscribe("LEARN_SKILL", self, "add_skill")

## Fills the skill dictionary with the skills in skill_list
func populate_dictionary()->void:
	skill_dictionary = {}
	for skill in skill_list:
		if skill == null:
			continue
		if skill.id in skill_dictionary:
			printerr("Duplicate Skill ID!")
			return
		if skill.id == "":
			printerr("Invalid Skill ID!")
			return
		skill_dictionary[skill.id] = skill

## Adds the skill matchin given id to the given character
func add_skill(data: Array)->void:
	if data[0] is not Character || data[1] is not String:
		printerr("Invalid arguments for add skill!")
		return
	if data[1] not in skill_dictionary:
		printerr("Attempted to learn invalid skill "+data[1])
		return
	data[0].add_skill(skill_dictionary[data[1]])
