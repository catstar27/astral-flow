extends Resource
class_name SkillEffect
## A passive effect granted by a skill, providing some kind of boost
##
## This class does not actually do anything, and is used to visually split skills into simple effects

@export var display_name: String = "Name Here" ## Name for this effect
@export_multiline var description: String = "Description" ## Description for this effect
@export var icon: Texture2D ## Icon for this effect
