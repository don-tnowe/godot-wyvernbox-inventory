tool
extends EditorPlugin


var inspector_plugins = [
	load("res://addons/wyvernbox/editor/inspector_plugin_inventory_creator.gd").new(self),
	load("res://addons/wyvernbox/editor/inspector_plugin_item_tables.gd").new(self),
]


func _enter_tree():
	for x in inspector_plugins:
		add_inspector_plugin(x)

	initialize_setting("input/menu_inventory", {
		"deadzone" : 0.2,
		"events" : [
			create_input_event(InputEventKey, KEY_TAB),
			create_input_event(InputEventKey, KEY_I),
			create_input_event(InputEventJoypadButton, JOY_SELECT),
		]
	})
	initialize_setting("input/inventory_less", {
		"deadzone" : 0.01,
		"events" : [
			create_input_event(InputEventKey, KEY_ALT),
			create_input_event(InputEventJoypadButton, JOY_L2),
		]
	})
	initialize_setting("input/inventory_more", {
		"deadzone" : 0.01,
		"events" : [
			create_input_event(InputEventKey, KEY_SHIFT),
			create_input_event(InputEventJoypadButton, JOY_R2),
		]
	})
	initialize_setting("input/inventory_filter", {
		"deadzone" : 0.01,
		"events" : [
			create_input_event(InputEventKey, KEY_F),
			create_input_event(InputEventJoypadButton, JOY_XBOX_Y),
		]
	})


func _exit_tree():
	for x in inspector_plugins:
		remove_inspector_plugin(x)


func initialize_setting(key, value):
	if !ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, value)


func create_input_event(event_type, input_index):
	var event = event_type.new()
	if event_type == InputEventKey: event.scancode = input_index
	if event_type == InputEventMouse: event.button_index = input_index
	if event_type == InputEventJoypadButton: event.button_index = input_index
	if event_type == InputEventJoypadMotion: event.axis = input_index
	return event
