extends CutsceneEvent
class_name DialogueCutsceneEvent
## A cutscene event that opens dialogue

@export var dialogue: DialogicTimeline ## Dialogue for this event to play
@export var pause_music: bool = false ## Whether to pause music when entering the dialogue
