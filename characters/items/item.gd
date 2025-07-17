extends Resource
class_name Item
## Represents an in game item which is stored in the inventory

@export var display_name: String = "Name Here" ## Display name of the item
@export_multiline var description: String = "Description" ## Description of the item
@export var id: String = "ID" ## ID of this item
@export var icon: Texture2D ## Icon of this item
@export var name_color: Color = Color.WHITE ## Color of this item's name
@export var hp_cost: int = 0 ## HP cost to use this item
@export var ap_cost: int = 0 ## AP cost to use this item (only applies in combat)
@export var mp_cost: int = 0 ## MP cost to use this item
@export var is_consumed: bool = false ## Whether this item is destroyed on use
