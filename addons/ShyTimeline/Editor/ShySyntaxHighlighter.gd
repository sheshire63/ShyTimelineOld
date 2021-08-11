@tool
extends SyntaxHighlighter


var regex_a := RegEx.new()
const colors = {
	"{}": Color.AQUAMARINE,
	"[]": Color.DARK_GRAY,
	"<>": Color.AQUA,
	"()": Color.HOT_PINK,
}

func _init():
	if regex_a.compile("[^\\\\][\\{\\}<>\\(\\)\"\\[\\]]") != OK:
		print("failed to compile SyntaxHighlighterRegex")
		


func _get_line_syntax_highlighting(line: int) -> Dictionary:
	print("mew")
	var result = {}
	var last_clamps = []
	var text = get_text_edit().get_line(line)
	var clamps = regex_a.search_all(text)
	for i in clamps:
		var brackets := ""
		var is_opening := false
		match i.strings[0]:
			"(", "[", "{", "<":
				is_opening = true
				continue
			"{", "}":
				brackets = "{}"
			"<", ">":
				brackets = "<>"
			"(", ")":
				brackets = "()"
			"[", "]":
				brackets = "[]"
			"\"":
				brackets = "\""
				if last_clamps.is_empty() and last_clamps[-1] != "\"":
					is_opening = true
		if is_opening:
			if brackets in colors:
				last_clamps.append(brackets)
				result[i.get_start()] = {"colors": colors[brackets]}
		else:
			if brackets in colors and last_clamps[-1] == brackets:
				last_clamps.pop_back()
				result[i.get_start()] = {"colors": colors[last_clamps[-1]]}
	return result
