@tool
extends Node
class_name SkillManager
## Manages allocation of skills to characters

@export var skill_path: String ## Path to folder containing skills
@export_tool_button("Repopulate Skills and Breakthroughs") var repopulate_dictionaries: Callable = populate_dictionaries
@export_storage var skill_dictionary: Dictionary[String, Skill] ## Dictionary linking skills and their ids

func _ready() -> void:
	if not Engine.is_editor_hint():
		EventBus.subscribe("ADD_SKILL", self, "add_skill")
		EventBus.subscribe("ADD_BREAKTHROUGH", self, "add_breakthrough")
	else:
		populate_dictionaries()

## Fills the skill dictionary with the skills in skill_list
func populate_dictionaries()->void:
	if !DirAccess.dir_exists_absolute(skill_path):
		printerr("Invalid Path For Skills!")
		return
	skill_dictionary.clear()
	var skill_folder: DirAccess = DirAccess.open(skill_path)
	for item in skill_folder.get_files():
		item = skill_path+item
		if item.right(5) == ".tres":
			var res: Resource = load(item)
			if res is Skill:
				if res.id in skill_dictionary:
					printerr("Duplicate Skill ID!")
					return
				if res.id == "":
					printerr("Invalid Skill ID!")
					return
				skill_dictionary[res.id] = res
	print(skill_dictionary)

## Adds the skill matching given id to the given character
func add_skill(data: Array)->void:
	if data[0] is not Character || data[1] is not String:
		printerr("Invalid arguments for add skill!")
		return
	if data[1] not in skill_dictionary:
		printerr("Attempted to learn invalid skill "+data[1])
		return
	data[0].add_skill(skill_dictionary[data[1]])
