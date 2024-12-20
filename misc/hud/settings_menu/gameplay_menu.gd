extends SettingsMenuChild
class_name GameplayMenu

@onready var selection_color: ColorPickerButton = %SelectionColor
@onready var attack_color: ColorPickerButton = %AttackColor
@onready var support_color: ColorPickerButton = %SupportColor

func _ready() -> void:
	set_values()

func selection_color_changed(color: Color) -> void:
	Settings.change_gameplay("selection_tint", color)

func attack_color_changed(color: Color) -> void:
	Settings.change_gameplay("attack_indicator_tint", color)

func support_color_changed(color: Color) -> void:
	Settings.change_gameplay("support_indicator_tint", color)

func set_values()->void:
	selection_color.color = Settings.gameplay.selection_tint
	attack_color.color = Settings.gameplay.attack_indicator_tint
	support_color.color = Settings.gameplay.support_indicator_tint
