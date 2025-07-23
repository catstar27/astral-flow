extends Node
class_name ItemManager
## Manages a Character's inventory and item abilities

var item_dict: Dictionary[Item, int] ## Dictionary of items and counts

## Adds an item to the character's inventory
func add_item(item: Item, amount: int = 1)->void:
	if item in item_dict:
		item_dict[item] += amount
	else:
		item_dict[item] = amount

## Activates an item
func activate_item(item: Item, amount: int = 1)->void:
	if item.item_dialogue != null:
		EventBus.broadcast("ENTER_DIALOGUE", [item.item_dialogue, false])
	if item.item_ability != null:
		item.item_ability.user = get_parent()
		get_parent().activate_ability(item.item_ability, get_parent().position)
	if item.is_consumed:
		item_dict[item] -= amount
		if item_dict[item] <= 0:
			item_dict.erase(item)
		if item.byproduct_item != null:
			if item.byproduct_item in item_dict:
				item_dict[item.byproduct_item] += 1
			else:
				item_dict[item.byproduct_item] = 1

#region Save and Load
## Gets a dictionary with saved values
func get_save_data()->Dictionary[String, int]:
	var dict: Dictionary[String, int]
	for item in item_dict.keys():
		if item.resource_path != "":
			dict[item.resource_path] = item_dict[item]
	return dict

## Loads the status effects from given data
func load_save_data(data: Dictionary[String, int])->void:
	item_dict.clear()
	for value in data:
		add_item(load(value), data[value])
#endregion
