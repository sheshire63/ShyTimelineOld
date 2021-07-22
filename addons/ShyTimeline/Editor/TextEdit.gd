extends VBoxContainer
tool

onready var text := $TextEdit
var event: Resource setget _setevent


func _ready() -> void:
	if event:
		text.text = event.text
	text.add_color_region('"', '"', Color.aquamarine)
#	text.add_color_region("{", "}", Color.mediumpurple)
#	text.add_color_region("[", "]", Color.webmaroon)
	text.add_color_region("<", ">", Color.teal)
#	for i in variables:
#		text.add_keyword_color(i, Color.cadetblue)


func _on_TextEdit_symbol_lookup(symbol: String, row: int, column: int) -> void:
	pass


func _on_Bold_pressed() -> void: #to func for custom bracket
	if text.is_selection_active():
		var from_line: int = text.get_selection_from_line()
		var from_pos: int = text.get_selection_from_column()
		var to_line: int = text. get_selection_to_line()
		var to_pos: int = text.get_selection_to_column()
		text.set_line(to_line, text.get_line(to_line).insert(to_pos, "[/b]"))
		text.set_line(from_line, text.get_line(from_line).insert(from_pos, "[b]"))
		text.update()
	else:
		text.insert_text_at_cursor("[b][/b]")
		text.cursor_set_column(text.cursor_get_column() + 3)
		text.update()
		text.grab_focus()

"""
ideas:
	-use stoppoint for waitpoit
	-spellcheck
		-color the words red?
		-open menu when the word is rightclicked?
		-how is the lookup in gdscript handeld?
"""


func _on_TextEdit_text_changed() -> void:
	if event:
		event.text = text.text
	else:
		printerr("no event to save to")


func _setevent(new) -> void:
	event = new
	text.text = event.text
