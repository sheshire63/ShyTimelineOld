extends Resource
tool


export var next_events := {0 : []}
export var pos := Vector2.ZERO
export var channel := ""


func get_node_type() -> String:
	return "BaseNode"


func create_control(id: int) -> Control:
	var new = Label.new()
	new.text = str(id)
	return new


func slot_removed(idx: int) -> void:
	pass

"""
throw event res out and just create an dictionary? in a new class?
	pro:
		better saving behavior / subresources somehow dont get saved automaticly
	
	contra
		how to edit them / inspector will not realy work then
make them objects instead of resource?
		
#"""
