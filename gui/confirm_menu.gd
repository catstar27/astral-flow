extends PanelContainer
class_name ConfirmMenu
## Menu for a confirmation

@onready var confirm_label: Label = %ConfirmLabel

signal confirmation_given(confirmed: bool) ## Emitted when a button was pressed, giving true or false

## Cancels current confirmation
func cancel_confirmation() -> void:
	hide()
	confirmation_given.emit(false)

## Confirms current confirmation
func confirm() -> void:
	hide()
	confirmation_given.emit(true)
