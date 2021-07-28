extends Node
tool


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
var data := {"text": ""}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _get_property_list() -> Array:
	return[{
		"name": "data.text",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT
	}]


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
