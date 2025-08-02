extends DialogicNode_ChoiceButton

func _load_info(info:Dictionary) -> void:
	# Load text and visibility
	super(info)

	if info.get("only_once", false) and info.get("visited_before", false):
		disabled = true
