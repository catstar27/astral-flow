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

func remove_subscriber(node)->void:
	for event in events:
		for sub_info in events[event]:
			if sub_info.node == node:
				events[event].erase(sub_info)

func broadcast(id: String, data)->void:
	var event: Event = Event.new(id, data)
	if event.id not in events:
		return
	var subscribers: Array = events[event.id]
	for sub_info in subscribers:
		if !is_instance_valid(sub_info.node):
			remove_subscriber(sub_info.node)
		elif sub_info.node.has_method(sub_info.fn):
			if event.data is String && event.data == "NULLDATA":
				sub_info.node.call(sub_info.fn)
			else:
				sub_info.node.call(sub_info.fn, event.data)
