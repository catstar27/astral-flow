extends Node

var events: Dictionary = {}

class SubscribeInfo:
	var node: Node
	var fn: String
	func _init(new_node: Node, new_fn: String) -> void:
		node = new_node
		fn = new_fn
	func _to_string() -> String:
		return "("+str(node)+", "+fn+")"

class Event:
	var data
	var id: String
	func _init(new_id: String, new_data) -> void:
		data = new_data
		id = new_id
	func _to_string() -> String:
		return "["+id+", "+str(data)+"]"

func subscribe(id: String, node: Node, fn: String)->void:
	if id not in events:
		events[id] = []
	for sub_info in events[id]:
		if sub_info.node == node && sub_info.fn == fn:
			return
	events[id].append(SubscribeInfo.new(node, fn))
	print(events)

func remove_subscriber(node: Node)->void:
	for event in events:
		for sub_info in event:
			if sub_info.node == node:
				event.erase(sub_info)
	print(events)

func broadcast(event: Event)->void:
	print(event)
	if event.id not in events:
		return
	for sub_info in events[event.id]:
		if !is_instance_valid(sub_info.node):
			remove_subscriber(sub_info.node)
		elif sub_info.node.has_method(sub_info.fn):
			sub_info.node.call(sub_info.fn, event.data)
	print(events)
