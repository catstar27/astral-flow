extends Button
class_name ControlDisplayButton
## Button holding a keybind
##
## Changes its visuals to match the current controller

@export var input_action_name: String ## Name of the input this will display
@onready var key_label: Label = %KeyLabel ## Label for if this is a keyboard key
enum control_types { ## Contains the types of controls this can show
	keyboard, ## For keyboard and mouse
	xbox, ## For XBox controllers. Also used as fallback if controller type is not detected
	playstation, ## For Playstation controllers
	nintendo ## For Nintendo controllers
}
var controller_tex: AtlasTexture = AtlasTexture.new() ## Texture to contain the relevant controls
var xbox_buttons: Texture2D = preload("res://textures/hud/xbox_buttons.png") ## XBox button spritesheet
var playstation_buttons: Texture2D = preload("res://textures/hud/playstation_buttons.png") ## Playstation button spritesheet
var nintendo_buttons: Texture2D = preload("res://textures/hud/nintendo_buttons.png") ## Nintendo button spritesheet
var keyboard_key: Texture2D = preload("res://textures/hud/keyboard_key.png") ## Keyboard key sprite
var large_keyboard_key: Texture2D = preload("res://textures/hud/keyboard_key_large.png") ## Large keyboard key sprite (for space, ctrl, etc)
var recent_control_type: control_types = control_types.keyboard ## Most recent control type
var prev_control_type: control_types = control_types.keyboard ## Previous control type
var last_device_name: String = "" ## Name of last detected input device
signal display_updated ## Emitted when the button changes control schemes

func _ready() -> void:
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
		update_display(recent_control_type)
		display_updated.emit()

func _input(event: InputEvent) -> void:
	if visible:
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
			update_display(recent_control_type)
			display_updated.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released(input_action_name):
		get_viewport().set_input_as_handled()

## Updates the display when controls or controllers change
func update_display(type: control_types)->void:
	key_label.hide()
	match type:
		control_types.keyboard:
			update_keyboard_display()
		control_types.xbox:
			controller_tex.atlas = xbox_buttons
			update_controller_display()
		control_types.playstation:
			controller_tex.atlas = playstation_buttons
			update_controller_display()
		control_types.nintendo:
			controller_tex.atlas = nintendo_buttons
			update_controller_display()

## Updates the sprite on the controller scheme spritesheet to match this button
func update_controller_display()->void:
	icon = controller_tex
	for event in InputMap.action_get_events(input_action_name):
		if event is InputEventJoypadButton:
			controller_tex.region.position.x = 32*(event.button_index%4)
			controller_tex.region.position.y = 32*(event.button_index/4)
			return

## Updates the keyboard key or mouse button displayed here
func update_keyboard_display()->void:
	for event in InputMap.action_get_events(input_action_name):
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
