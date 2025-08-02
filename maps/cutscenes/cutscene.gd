extends Resource
class_name Cutscene
## Simple class containing the name of a character and a schedule to link to that character

@export var cutscene_stages: Array[CutsceneStage] ## Array of events in this cutscene
var current_stage: int = 0
