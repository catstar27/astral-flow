extends CutsceneEvent
class_name CharacterCutsceneEvent
## A cutscene event targeting a character

enum event_type{MOVE, INTERACT, ABILITY, ACTIVATE}
@export var target_name: String ## Name of the character to control
@export var type: event_type ## The action this event will take
@export var pos: Vector2 ## Position to move to or activate at
@export var interact_target: String ## Name of the interactive/character to interact with
@export var ability: Ability ## Ability to activate
