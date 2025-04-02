extends Resource
class_name Skill
## Represents a skill for a character

@export var id: String ## ID for this skill
@export_multiline var display_name: String ## Name of this skill
@export var skill_effects: Array[SkillEffect] ## Effects granted by this skill
@export var abilities: Array[Ability] ## Abilities granted by this skill
@export_group("Dependencies")
@export var required_skills: Array[Skill] ## List of skills needed before this can be learned
@export var required_breakthroughs: Array[Breakthrough] ## List of breakthroughs needed to learn this skill
