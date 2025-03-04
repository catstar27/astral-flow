extends Node
## Tracks subscriptions and broadcasts events to all nodes that subscribe to them

var events: Dictionary[String, Array] = {} ## Contains linked subscription info and event ID

class SubscribeInfo: ## Class holding data on a subscription
	var node: Node ## The node this represents
	var fn: String ## The function to be called when triggered
	func _init(new_node: Node, new_fn: String) -> void:
		node = new_node
		fn = new_fn
	func _to_string() -> String:
		return "("+str(node)+", "+fn+")"

class Event: ## Event class containing data and an ID
	var data ## Passed to functions called by this event
	var id: String ## ID of the event; matched with subscriber subscriptions
	func _init(new_id: String, new_data) -> void:
		data = new_data
		id = new_id
	func _to_string() -> String:
		return "["+id+", "+str(data)+"]"

## Subscribes the given node to events of given ID to a given function
func subscribe(id: String, node: Node, fn: String)->void:
	if id not in events:
		events[id] = []
	for sub_info in events[id]:
		if sub_info.node == node && sub_info.fn == fn:
			return
	events[id].append(SubscribeInfo.new(node, fn))

## Removes all subscriptions from a subscriber
func remove_subscriber(node)->void:
	for event in events:
		for sub_info in events[event]:
			if sub_info.node == node:
				events[event].erase(sub_info)

## Shorthand for broadcast_event that can take data and ID and makes the event
func broadcast(id: String, data)->void:
	broadcast_event(Event.new(id, data))

## Broadcasts the passed event to all relevant subscribers
func broadcast_event(event: Event)->void:
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
