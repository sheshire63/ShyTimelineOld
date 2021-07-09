extends Resource
tool


#export var name := ""# do we need this?
#export var data := {} # use attributes in the childevents instead for handling in the editor
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
