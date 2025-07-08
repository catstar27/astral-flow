extends Button
class_name QuestButton
## Button that references a quest, and emits that quest in a signal when pressed

var quest: QuestInfo ## Quest this button references
signal pressed_quest(button: QuestButton, quest: QuestInfo) ## Emitted when pressed, sends the button and quest
signal unpressed_quest(quest: QuestButton) ## Emitted when unpressed, sends the quest
signal focused_quest(quest: QuestInfo) ## Emitted when the button is focused, sends the quest

## Chooses which signal to emit when button is pressed based on its status
func manage_quest_signal(on: bool)->void:
	if on:
		pressed_quest.emit(self, quest)
	else:
		unpressed_quest.emit(quest)

## Emits the focused_quest signal
func focus_quest()->void:
	focused_quest.emit(quest)

## Selects the given quest and updates the button
func select_quest(new_quest: QuestInfo)->void:
	quest = new_quest
	icon = quest.quest_icon
	text = quest.quest_name
