extends Node


var _regex1 := RegEx.new()# to get the content of brackets
var _regex2 := RegEx.new()# to get the seperate contents of regex 1
var _regex3 := RegEx.new()# to split the text in segments and setting commands

var variables := {
	"player": {
		"type": TYPE_STRING,
		"value": "Lin"},
	}


func _ready() -> void:
	_compile_regex()


func _compile_regex() -> void:
	#fetches the text up to the current bracket
	var pre := "(?<pre>[\\w\\W]*?)"
	
	#fetches the content of a bracket without a /another nested bracked inside
	var inner := "(?<inner>(?:\\\\{|}|[^\\{}])*?)"
	if _regex1.compile(pre + "{\\s*" + inner + "\\s*}") != OK:
		printerr("failed to compile regex1")
	
	var text := "(?:\"(?<{0}>(?:\\\\\"|[^\"])*)\")"
	var variable := "(?:<(?<{0}>\\w+)>)"
	var number := "(?<{0}>\\-?\\d+\\.?\\d*)"
	var boolean := "(?<{0}>(?:[Tt]rue)|[[Ff]alse])"
	var nested := "(?:\\((?<{0}>[\\w\\W]*?)\\))"
	var operator := "(?<operator>(?:[\\+\\-]|\\*{1,2}|\\/{1,2}|(?:[<>=!]=)|<>))"
	var part_a := (
			"(?:"+
				"(?:"#Text as String or Var or nested function
					+ nested.format(["text"]) + 
					"|" + text.format(["text"]) +
					"|" +  variable.format(["var"]) +
				")\\s*" + 
				"(?:" + #opt. 
					"(?:" #weight as value or var / or variable for condition
						+ number.format(["number1"]) +
						"|" + variable.format(["var1"]) +
						"|" + text.format(["text1"]) + 
					")\\s*"+
					"(?:" +
						operator + "\\s*" +
						"(?:" + #opt. operator and compare value as text, number or variable
							variable.format(["var2"]) + 
							"|" + text.format(["text2"]) +
							"|" + number.format(["number2"]) + 
						")" +
					")?" + 
				")?" +
			")")
	var part_b := (
			"(?:" +
				variable.format(["var3"]) +
				"\\s*(?<operator2>[\\+\\-\\*/]?=)\\s*" + 
				"(?:" +
					variable.format(["var4"]) +
					"|" + text.format(["text3"]) +
					"|" + number.format(["number3"]) +
				")" +
			")")
	if _regex2.compile(
			"\\G\\s*(?:" +
				"(?:" + part_a + "\\s*" + part_b + ")" +
				"|" + part_b +
				"|" + part_a +
			")\\s*,") != OK:
		printerr("failed to compile regex2")
	
	pre = "(?<pre>[\\w\\W]*?)"
	number = "(?<{0}>\\-?\\d+\\.?\\d*)"
	#operator = "(?<operator>[\\+\\-\\*/!])?"
	if _regex3.compile( pre + "{\\s*(?<option>\\w+)\\s*(?::\\s*(" + number.format(["value"]) + "|" + text.format(["value"]) + ")\\s*)?}") != OK:
		printerr("failed to compile regex3")


func format_text(text: String, sender) -> Array:
	text += "{end_line}"
	var segments := []
	text = text.replace("\n", "{end_line}")
	for i in _regex3.search_all(text):
		var segment := {}
		segment["text"] = i.get_string("pre")
		segment["option"] = i.get_string("option")
		segment["value"] = i.get_string("value")
		#segment["operator"] = i.get_string("operator")
		segments.append(segment)
	
	var override_settings := {}
	for i in segments:
		if ! i.option in ["wait", "w", "continue", "cont", "c"]:
			if i.value != "":
				override_settings[i.option] = i.value
			else:
				override_settings.erase(i.option)
		
		i.text = format_line(i.text, sender)
	return segments


func format_line(text:String, sender, override_settings := {}) -> String:
	var doo = true
	while doo:
		var temp = text
		var do = true
		while do:
			var tmp = text
			text = _format_step(text)
			do = tmp != text
		
		do = true
		while do:
			var tmp = text
			text = text.format(get_values(), "<_>")
			do = tmp != text
		
		if override_settings.get("remove_double_spaces",
				sender.get_setting("remove_double_spaces")):
			do = true
			while do:
				var tmp = text
				text = text.replace("  ", " ")
				do = tmp != text
		doo = temp != text
	return text

func _format_step(text:String) -> String:
	text += "{}"
	var result := ""
	var r = _regex1.search_all(text)
	for i in r:
		result += i.get_string("pre")
		var r2 = _regex2.search_all(i.get_string("inner") + ",")
		var total = 0.0
		var weights = []
		var defaults = []
		weights.resize(r2.size())
		for j in r2.size():
			var operator = r2[j].get_string("operator")
			var weight := -1.0
			if operator == "": #just weight
				var number = r2[j].get_string("number1")
				var var1 = r2[j].get_string("var1")
				weight = float(number) if number != "" else weight
				weight = float(variables.get(var1, {}).get("value", 0.0)) if var1 != "" else weight
				if weight < 0.0:#add to list and set weight later?
					weight = 0.0
					defaults.append(j)
			else:
				weight = 0.0
				var var1 = r2[j].get_string("var1")
				var var2 = r2[j].get_string("var2")
				var text1 = str(variables.get(var1, {}).get("value", r2[j].get_string("text1")))
				var text2 = str(variables.get(var2, {}).get("value", r2[j].get_string("text2")))
				var number1 = float(variables.get(var1, {}).get("value",
						r2[j].get_string("number1")))
				var number2 = float(variables.get(var2, {}).get("value",
						r2[j].get_string("number2")))
				match operator:
					"+":
						weight = number1 + number2
					"-":
						weight = number1 - number2
					"*":
						weight = number1 * number2
					"/":
						weight = number1 / number2
					"**":
						weight = pow(number1, number2)
					"//":
						weight = pow(number2, 1.0 / number1)
					"<", "<=", "<>":
						weight = 1.0 if number1 < number2 else weight
						continue
					">", ">=", "<>":
						weight = 1.0 if number1 > number2 else weight
						continue
					"<=", ">=":
						weight = 1.0 if number1 == number2 else weight
					"==":
						weight = 1.0 if text1 == text2 else weight
					"!=":
						weight = 1.0 if text1 != text2 else weight
					var err:
						printerr("invalid operator: %s"%err)
			total += weight
			weights[j] = weight
		if total < 1.0:
			for j in defaults:
				weights[j] = (1.0 - total) / defaults.size()
		var rand_c = randf() * max(1.0, total)
		for j in r2.size():
			if weights[j] != null:
				rand_c -= weights[j]
				if rand_c <= 0.0:
					result += str(variables.get(r2[j].get_string("var"), {}).get("value", r2[j].get_string("text")))
					var var3 = r2[j].get_string("var3")
					var var4 = r2[j].get_string("var4")
					var text3 = r2[j].get_string("text3")
					var boolean
					var value = float(r2[j].get_string("number3")) if r2[j].get_string("number3") != "" else text3
					var b = variables.get(var4, {}).get("value", value)
					if not var3 in variables:
						if var4:
							variables[var3] = {"value": null, "type": variables[var4].type}
						elif text3:
							variables[var3] = {"value": "", "type": TYPE_STRING}
						elif boolean:
							variables[var3] = {"value": "", "type": TYPE_BOOL}
						elif r2[j].get_string("number").is_valid_integer:
							variables[var3] = {"value": "", "type": TYPE_INT}
						else:
							variables[var3] = {"value": "", "type": TYPE_REAL}
					match variables[var3].type:
						TYPE_INT:
							b = int(b)
						TYPE_BOOL:
							b = bool(b)
						TYPE_REAL:
							b = float(b)
						TYPE_STRING:
							b = str(b)
					match r2[j].get_string("operator2"):
						"=":
							variables[var3].value = b
						"+=":
							variables[var3].value += b
						"-=":
							variables[var3].value -= b
						"*=":
							variables[var3].value *= b
						"/=":
							variables[var3].value /= b
					break
	return result


func get_values() -> Dictionary:
	var values = {}
	for i in variables:
		values[i] = variables[i].value
	return values

#Syntax: Normal Text <variable> {"Text A 1:1", "Text B" {"Text A weight" 0.5, "Default"} {"Text chance by var" <var>*1} {<var> 1, "alternative" 1} {"text" <var> == 1.0}... 
# does not work: {"Text" <var>="some text"} -> some text gets converted to a float ???? should work

#{"text" [<weight_variable>]}
#{"text" [weight]}
#{<variable> weight]}
#{<variable> [<weight_variable>]}
#{"text" [<variable> operator <variable>]}
#{wait} # adds a wait point
#{wait: 1.0} adds a timed wait point
#{end_line} wait point for the end of line
#{continue} trigers events that are connected to the first slot of the current event
#{continue: 3} triggers events that are connected to the 3rd slot of the current event
#{override_setting: 1.0} overrides a setting for the rest of the current event

#wip
#{override_setting} resets a overridden setting
#{<var> = value} set variable
#{<var> += value} and *= /= -=	-= also for invert bool
#{"text" weight <var> += 3} change a variable if the option is choosen
	
