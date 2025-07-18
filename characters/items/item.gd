extends Resource
class_name Item
## Represents an in game item which is stored in the inventory

@export var display_name: String = "Name Here" ## Display name of the item
@export_multiline var description: String = "Description" ## Description of the item
@export var id: String = "ID" ## ID of this item
@export var icon: Texture2D ## Icon of this item
@export var name_color: Color = Color.WHITE ## Color of this item's name
@export var is_consumed: bool = false ## Whether this item is destroyed on use
@export var item_ability: Ability ## The ability that is activated when this item is used
@export var item_dialogue: DialogicTimeline ## Dialogue triggered when this item is used

## Prepares the item resource
func setup()->void:
	description += "\nAP Cost: "+str(item_ability.ap_cost)+"\nMP Cost: "+str(item_ability.mp_cost)+"\nRange: "
	if item_ability.target_type == item_ability.target_type_options.user:
		description += "Self"
	elif item_ability.ability_range == 1:
		description += "Melee"
	else:
		description += str(item_ability.ability_range)+" Tiles"
