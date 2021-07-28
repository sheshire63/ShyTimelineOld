extends Node

const _SET_VAR_OPERATORS := ["=", "+=", "*=", "-=", "/=", "**=", "//=", "=!"]

var _regex_brackets := RegEx.new()# to get the content of brackets
var _regex_segments := RegEx.new()# to get the seperate contents of regex 1
var _regex_subsegments := RegEx.new()# to split the text in segments and setting commands
var _regex_escaped_chars := RegEx.new()

var variables := {
	"player": "Lin",
	}


func _ready() -> void:
	_compile_regex()


func _compile_regex() -> void:
	#fetches the text up to the current bracket
	var outer := "(?<outer>[\\w\\W]*?)"
	
	#fetches the content of a bracket
	var inner := "(?<inner>(?:[^\\{\\}]|\"(?:[^\"]|\\\\\")*\")*?)"
	if _regex_brackets.compile(outer + "{\\s*" + inner + "\\s*}") != OK:
		printerr("failed to compile _regex_brackets")
	
	#splits into segments divided by ",".ignores strings
	if _regex_segments.compile("((?:(?:[^\\\\]?|(?:\\\\\\\\)+)\"[\\w\\W]*?(?:[^\\\\]?|(?:\\\\\\\\)+)\"|[^,])*),") != OK:#bug \\" will not work(an escaped backslash before the ")
		#check regex for even times
		printerr("failed to compile _regex_segments")
	
	#splits segments into values and operators
	var text := "(?:\"(?<text>(?:\\\\\"|[^\"])*)\")"
	var integer := "(?<int>\\-?\\d+)"
	var real := "(?<float>\\-?\\d+\\.\\d+)"
	var boolean := "(?<bool>(?:[Tt]rue)|[[Ff]alse])"
	var action := "(?<action>[\\w_]+)\\((?<arg>[\\w\\W]*?)\\)"
	var setting := "((?<setting>[\\w_]+)(?:\\." + action + "))"
	var variable := "(?:<(?<var>[\\w_]+)>(?:\\." + action + ")?)"
	var nested := "(?<nested_recursion>\\((?<nested>(?:[^\\(\\)]|\\g'nested_recursion')*)\\))"
	if _regex_subsegments.compile("\\G\\s*(?:(?<operator>[\\+\\-*/=|&%]{1,3})\\s*)?(?:"
			+ text + "|" + variable + "|" + real + "|"+ integer
			+ "|" + boolean + "|" + setting + "|" + action
			+ ")") != OK:
		printerr("failed to compile _regex_subsegments")
	
	if _regex_escaped_chars.compile("\\\\\\S") != OK:
		printerr("failed to compile _regex_escaped_chars")


func format_text(text: String, replace_new_lines := false) -> Array:
	text += "{wait()}"
	var lines := []
	if replace_new_lines:
		text = text.replace("\n", "{end_line()}")
	for i in _regex_brackets.search_all(text):
		lines.append({"text": i.get_string("outer").format(variables, "<_>")})
		lines.append_array(_handle_bracket(i.get_string("inner")))
	for i in lines.size():
		if lines[i].has("text"):
			lines[i].text = lines[i].text.replace("\\n", "\n")#also for other escpes(\s,\t)?
			var regex_mach := _regex_escaped_chars.search(lines[i].text)
			while regex_mach:
				lines[i].text = text.erase(regex_mach.get_start(), 1)
				regex_mach = _regex_escaped_chars.search(lines[i].text, regex_mach.get_start() + 1)
	return lines


func _handle_bracket(line: String) -> Array:
	line += ","
	var actions = []
	var weights = []
	for j in _regex_segments.search_all(line):
		actions.append([])
		weights.append([])
		var is_weight = false
		var is_action = true
		var tmp = []
		for k in _regex_subsegments.search_all(j.strings[1]):
			if k.get_string("operator") == "" and tmp:
				if is_weight:
					weights[-1].append_array(tmp)
					is_weight = false
				else:
					actions[-1].append_array(tmp)
					is_action = false
					is_weight = true
				tmp = []
			elif k.get_string("operator") in _SET_VAR_OPERATORS:
				is_action = true
				is_weight = false
			tmp.append(k)
		if is_action:
			actions[-1].append_array(tmp)
		else:
			weights[-1].append_array(tmp)
	
	var total_weight = 0
	for j in weights.size():
		if weights[j]:
			weights[j] = float(_add_up_values(weights[j]))
			total_weight += weights[j]
	var defaults = weights.count([])
	for j in weights.size():
		if weights[j] is Array:
			weights[j] = max(0.0, (1.0 - total_weight) / defaults)
	var random = rand_range(0.0, max(total_weight, 1.0))
	for j in weights.size():
		random -= weights[j]
		if random <= 0.0:
			return _handle_actions(actions[j])
	return []


func _add_up_values(actions: Array):
	var value_a = ""
	while actions:
		var action = actions[0].get_string("operator")
		#get value:
		var value_b
		if actions[0].get_string("var") != "":
			value_b = variables.get(actions[0].get_string("var"))
			if actions[0].get_string("action") != "":
				match actions[0].get_string("action"):
					"default":
						if value_b == null:
							value_b = actions[0].get_string("arg")
					"type":
						match actions[0].get_string("arg"):
							"int":
								value_b = int(value_b)
							"bool":
								value_b = bool(value_b)
							"float":
								value_b = float(value_b)
							"string":
								value_b = str(value_b)
#		elif actions[0].get_string("setting") != "":
#			pass#handeld in _handle_action
#		elif actions[0].get_string("action") != "":
#			pass#handeld in _handle_action
		elif actions[0].get_string("int") != "":
			value_b = int(actions[0].get_string("int"))
		elif actions[0].get_string("float") != "":
			value_b = float(actions[0].get_string("float"))
		elif actions[0].get_string("bool") != "":
			value_b = true if actions[0].get_string("bool") == "true" else false
		elif actions[0].get_string("nested") != "":
			value_b = _handle_bracket(actions[0].get_string("nested"))
		else:
			value_b = actions[0].get_string("text")


		# add up:
		match action:
			"+":
				if value_a is String:
					value_a += str(value_b)
				elif value_a is int and value_b is int:
					value_a = value_a + value_b
				else:
					value_a = float(value_a) + float(value_b)
			"-":
				if value_a is int and value_b is int:
					value_a = value_a - value_b
				else:
					value_a = float(value_a) - float(value_b)
			"*":
				if value_a is String:
					value_a = value_a.repeat(int(value_b))
				elif value_a is int and value_b is int:
					value_a = value_a * value_b
				else:
					value_a = float(value_a) * float(value_b)
			"/":
				if float(value_b) == 0.0:
					value_a = 0 if value_a is int else 0.0
				else:
					if value_a is int and value_b is int:
						value_a = int(value_a / value_b)
					else:
						value_a = float(value_a) / float(value_b)
			"**":
				if value_a is int and value_b is int:
					value_a = int(pow(value_a, value_b))
				else:
					value_a = pow(float(value_a), float(value_b))
			"//":
				if value_a is int and value_b is int:
					value_a = int(pow(value_a, 1 / float(value_b)))
				else:
					value_a = pow(float(value_a), 1 / float(value_b))
			"%":
				value_a = int(value_a)%int(value_b)
			"==":
				value_a = value_a == value_b
			"!=":
				value_a = value_a != value_b
			"&":
				value_a = value_a and value_b
			"|":
				value_a = value_a or value_b
			"||":
				value_a = bool(value_a) != bool(value_b)
			"<":
				if value_a is String:
					if value_b is String:
						value_a = value_a.length() < value_b.length()
					else:
						value_a = value_a.length() < float(value_b)
				else:
					value_a = float(value_a) < float(value_b)
			">":
				if value_a is String:
					if value_b is String:
						value_a = value_a.length() > value_b.length()
					else:
						value_a = value_a.length() > float(value_b)
				else:
					value_a = float(value_a) > float(value_b)
			"<=":
				if value_a is String:
					if value_b is String:
						value_a = value_a.length() <= value_b.length()
					else:
						value_a = value_a.length() <= float(value_b)
				else:
					value_a = float(value_a) <= float(value_b)
			">=":
				if value_a is String:
					if value_b is String:
						value_a = value_a.length() >= value_b.length()
					else:
						value_a = value_a.length() >= float(value_b)
				else:
					value_a = float(value_a) >= float(value_b)
			"<>":
				if value_a is String:
					if value_b is String:
						value_a = value_a.length() != value_b.length()
					else:
						value_a = value_a.length() != float(value_b)
				else:
					value_a = float(value_a) != float(value_b)
			"<<":
				value_a = value_a << int(value_b)
			">>":
				value_a = value_a >> int(value_b)
			_:
				return value_b
		actions.pop_front()
	return value_a


func _handle_actions(actions: Array) -> Array:
	var result := []
	while actions:
		var entry = {}
		var action = actions[0].get_string("action")
		if action != "" and actions[0].get_string("var") == "":
			match action:
				_:
					entry.action = action
					entry.value = actions[0].get_string("arg")
					entry.setting = actions[0].get_string("setting")
		elif actions.size() > 1 and actions[1].get_string("operator") in _SET_VAR_OPERATORS:
			var variable = actions[0].get_string("var")
			var operator = actions[1].get_string("operator")
			actions.pop_front()
			var value = _add_up_values(actions)
			match typeof(variables.get(variable)):
				TYPE_BOOL:
					value = bool(value)
				TYPE_INT:
					value = int(value)
				TYPE_REAL:
					value = float(value)
				TYPE_STRING:
					value = str(value)
			match operator:
				"=":
					variables[variable] = value
				"+=":
					variables[variable] += value
				"-=":
					variables[variable] -= value
				"*=":
					variables[variable] *= value
				"/=":
					variables[variable] /= value
				"**=":
					variables[variable] = pow(variables[variable], value)
				"//=":
					variables[variable] = pow(variables[variable], 1 / value)
		else:
			result.append_array(format_text(_add_up_values(actions)))
		result.append(entry)
		actions.pop_front()
	return result


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
	
#"""
