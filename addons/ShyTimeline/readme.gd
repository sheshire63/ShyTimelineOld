extends Node


"""
How to:
	-Variables are currently created though events(not jet) and syntax or manualy in "res://addons/ShyTimeline/Globals/Vars.gd" variables dictionary
	-Settings are in multiple places and overwrite the higher ones:
		Global: Project Settings
		Timeline: exported setting
		Event Handler: exported Setting
		Text Event: via Text syntax:
			{override_setting(1.0)} overrides a setting for the text event, for rest of the event
				only for settings handeld by the text_handler
			{override_setting.clear()}
"""


"""
Known Issues:
	-Creating a new TimelineRes Copies the subresources from a previus instanced TimelineRes
		Problem lays in how Godot saves subresources or in a lack of understanding it on my part
	-nested strings are not formated if just in "<example>" use "{<example>}" instead
	-there might be some bugs when handling empty strings in vars
"""


"""
Planned Stuff / ideas
	templates for custom nodes/events/handlers
	handle variables
		custom docker
	?variable nodes
		?choose time from choice node
		??item count
			will get very complicated
	? actions for choices
		disable choice under condition
			?if text is empty
		? complex editor
	more nodes:
		condition
		await
			waits until it gets called x times
		?empty
			for node management
			will cause problems if there is no handler
				handle in timeline?
		input
			also a action
			different inputs:
				line
				text
				number
				range
				checkbox
			?option to create option menu from event
		start animation
			uses AnimationPlayer
			?action
		?set property / call function
		sprite handler
			position / animation
			animation / image
				?custom type for characters
		?end
			emits a finished signal with a value
		set_var
			creates or changes a variable
"""

"""
todo fix:
	add base nodes:
		slots right
		slots left
		both slots
		no extra slots(base)
	hide some exports from resource to prevent users from damaging them
		_get_property_list()
	vars second value does not get displayed?
		?default weights not working?
"""
