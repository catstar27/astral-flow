extends Button
class_name ControlDisplayButton

@export var input_action_name: String
@onready var key_label: Label = %KeyLabel
var controller_tex: AtlasTexture = AtlasTexture.new()
var xbox_buttons: Texture2D = preload("res://textures/hud/xbox_buttons.png")
var playstation_buttons: Texture2D = preload("res://textures/hud/playstation_buttons.png")
var nintendo_buttons: Texture2D = preload("res://textures/hud/nintendo_buttons.png")
var keyboard_key: Texture2D = preload("res://textures/hud/keyboard_key.png")
var large_keyboard_key: Texture2D = preload("res://textures/hud/keyboard_key_large.png")
var recent_control_type: control_types = control_types.keyboard
var prev_control_type: control_types = control_types.keyboard
var last_device_name: String = ""
enum control_types {keyboard, xbox, playstation, nintendo}
signal display_updated

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

func update_display(type: control_types)->void:
	key_label.hide()
	match type:
		control_types.keyboard:
			pass
		control_types.xbox:
			controller_tex.atlas = xbox_buttons
		control_types.playstation:
			controller_tex.texture = playstation_buttons
		control_types.nintendo:
			controller_tex.texture = nintendo_buttons
	if type != control_types.keyboard:
		icon = controller_tex
		for event in InputMap.action_get_events(input_action_name):
			if event is InputEventJoypadButton:
				controller_tex.region.position.x = 32*(event.button_index%4)
				controller_tex.region.position.y = 32*(event.button_index/4)
				return
	else:
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
