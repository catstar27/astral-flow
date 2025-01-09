extends Control
class_name UtilityMenu

@onready var info_container: VBoxContainer = %Info
@onready var menu_button: ControlDisplayButton = %MenuButton
@onready var top_button: Button = %Party
enum states{closed, open, suspended}
var state: states = states.closed
var changing_state: bool = false

func _ready() -> void:
	menu_button.display_updated.connect(update_menu_button)

func update_menu_button()->void:
	menu_button.position.x = -menu_button.size.x

func toggle_menu()->void:
	if state != states.closed:
		close_menu()
	else:
		open_menu()

func open_menu()->void:
	if state != states.closed || changing_state:
		return
	changing_state = true
	state = states.open
	menu_button.text = "→"
	modulate = Color(1,1,1,1)
	info_container.show()
	await create_tween().tween_property(info_container, "position", Vector2(-73, info_container.position.y), .5).finished
	EventBus.broadcast(EventBus.Event.new("DEACTIVATE_SELECTION", "NULLDATA"))
	top_button.grab_focus()
	changing_state = false

func close_menu()->void:
	if state == states.closed || changing_state:
		return
	changing_state = true
	var activate_selection: bool = true
	if state == states.suspended:
		activate_selection = false
	state = states.closed
	menu_button.text = "←"
	if activate_selection:
		EventBus.broadcast(EventBus.Event.new("ACTIVATE_SELECTION", "NULLDATA"))
	await create_tween().tween_property(info_container, "position", Vector2(0, info_container.position.y), .5).finished
	modulate = Color(1,1,1,1)
	info_container.hide()
	changing_state = false
