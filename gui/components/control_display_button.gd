@tool
extends Button
class_name ControlDisplayButton
## Button holding a keybind
##
## Changes its visuals to match the current controller

@export var input_action_name: String: ## Name of the input this will display
	set(ian):
		input_action_name = ian
		prep()
@onready var key_label: Label = %KeyLabel ## Label for if this is a keyboard key
enum control_types { ## Contains the types of controls this can show
	keyboard, ## For keyboard and mouse
	xbox, ## For XBox controllers. Also used as fallback if controller type is not detected
	playstation, ## For Playstation controllers
	nintendo ## For Nintendo controllers
}
var controller_tex: AtlasTexture = AtlasTexture.new() ## Texture to contain the relevant controls
var xbox_buttons: Texture2D = preload("uid://dex3nfkyghgto") ## XBox button spritesheet
var playstation_buttons: Texture2D = preload("uid://cr3hku7xo62gq") ## Playstation button spritesheet
var nintendo_buttons: Texture2D = preload("uid://btwblsu5qgtyu") ## Nintendo button spritesheet
var keyboard_key: Texture2D = preload("uid://bxhwtcxdgtkx6") ## Keyboard key sprite
var large_keyboard_key: Texture2D = preload("uid://cdsoyfxaorth3") ## Large keyboard key sprite (for space, ctrl, etc)
var recent_control_type: control_types = control_types.keyboard ## Most recent control type
var prev_control_type: control_types = control_types.keyboard ## Previous control type
var last_device_name: String = "" ## Name of last detected input device
signal display_updated ## Emitted when the button changes control schemes

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	match icon_alignment:
		HORIZONTAL_ALIGNMENT_LEFT:
			key_label.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		HORIZONTAL_ALIGNMENT_CENTER:
			key_label.set_anchors_preset(Control.PRESET_CENTER)
		HORIZONTAL_ALIGNMENT_RIGHT:
			key_label.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	controller_tex.region.size = Vector2.ONE*32
	shortcut = Shortcut.new()
	shortcut.events = InputMap.action_get_events(input_action_name)
	if !InputMap.has_action(input_action_name):
		printerr("Invalid Input Action "+input_action_name+" on Button "+name)
	else:
		update_display(recent_control_type, InputMap.action_get_events(input_action_name))
		display_updated.emit()

## Preps the button for display in editor
func prep()->void:
	if not Engine.is_editor_hint():
		return
	key_label = %KeyLabel
	match icon_alignment:
		HORIZONTAL_ALIGNMENT_LEFT:
			key_label.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		HORIZONTAL_ALIGNMENT_CENTER:
			key_label.set_anchors_preset(Control.PRESET_CENTER)
		HORIZONTAL_ALIGNMENT_RIGHT:
			key_label.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	controller_tex.region.size = Vector2.ONE*32
	shortcut = Shortcut.new()
	shortcut.events = ProjectSettings.get_setting("input/"+input_action_name).events
	if !ProjectSettings.has_setting("input/"+input_action_name):
		printerr("Invalid Input Action "+input_action_name+" on Button "+name)
	else:
		update_display(recent_control_type, ProjectSettings.get_setting("input/"+input_action_name).events)
		display_updated.emit()

func _input(event: InputEvent) -> void:
	if visible:
		var events: Array[InputEvent] = InputMap.action_get_events(input_action_name)
		if event is InputEventKey || event is InputEventMouse:
			last_device_name = ""
			prev_control_type = recent_control_type
			recent_control_type = control_types.keyboard
		elif last_device_name != Input.get_joy_name(event.device).to_lower():
			last_device_name = Input.get_joy_name(event.device).to_lower()
			if last_device_name.contains("xbox") || last_device_name.contains("microsoft"):
				prev_control_type = recent_control_type
				recent_control_type = control_types.xbox
			elif last_device_name.contains("ps") || last_device_name.contains("playstation"):
				prev_control_type = recent_control_type
				recent_control_type = control_types.playstation
			elif last_device_name.contains("nintendo") || last_device_name.contains("switch"):
				prev_control_type = recent_control_type
				recent_control_type = control_types.nintendo
			else:
				prev_control_type = recent_control_type
				recent_control_type = control_types.xbox
		elif last_device_name == Input.get_joy_name(event.device).to_lower():
			prev_control_type = recent_control_type
		if recent_control_type != prev_control_type:
			update_display(recent_control_type, events)
			display_updated.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released(input_action_name):
		get_viewport().set_input_as_handled()

## Updates the display when controls or controllers change
func update_display(type: control_types, events: Array)->void:
	key_label.hide()
	match type:
		control_types.keyboard:
			update_keyboard_display(events)
		control_types.xbox:
			controller_tex.atlas = xbox_buttons
			update_controller_display(events)
		control_types.playstation:
			controller_tex.atlas = playstation_buttons
			update_controller_display(events)
		control_types.nintendo:
			controller_tex.atlas = nintendo_buttons
			update_controller_display(events)

## Updates the sprite on the controller scheme spritesheet to match this button
func update_controller_display(events: Array)->void:
	icon = controller_tex
	for event in events:
		if event is InputEventJoypadButton:
			controller_tex.region.position.x = 32*(event.button_index%4)
			controller_tex.region.position.y = 32*(event.button_index/4)
			return

## Updates the keyboard key or mouse button displayed here
func update_keyboard_display(events: Array)->void:
	for event in events:
		if event is InputEventKey:
			if event.as_text_physical_keycode().length() > 1:
				key_label.size.x = 130
				icon = large_keyboard_key
			else:
				key_label.size.x = 66
				icon = keyboard_key
			key_label.text = event.as_text_physical_keycode().to_upper()
			key_label.show()
			return
		elif event is InputEventMouse:
			return
