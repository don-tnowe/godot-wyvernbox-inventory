extends EditorInspectorPlugin

var property_script =	load("res://addons/wyvernbox/editor/inspector_item_list.gd")

var plugin


func _init(plugin):
	self.plugin = plugin


func can_handle(object):
	return object is ItemConversion || object is ItemGenerator


func parse_property(object, type, path, hint, hint_text, usage):
	if path in ["input_counts", "output_ranges", "weights", "count_ranges"]:
		return true

	if path == "input_types":
		add_property_editor_for_multiple_properties(
			"Inputs",
			["input_types", "input_counts"],
			property_script.new(
				plugin,
				{
					"input_types" : object.input_types,
					"input_counts" : object.input_counts,
				},
				["Count"],
				[true],
				[1]
			)
		)
		return true

	if path == "output_types":
		add_property_editor_for_multiple_properties(
			"Outputs",
			["output_types", "output_ranges"],
			property_script.new(
				plugin,
				{
					"output_types" : object.output_types,
					"output_ranges" : object.output_ranges,
				},
				["Min", "Max"],
				[true],
				[Vector2(1, 1)]
			)
		)
		return true

	if path == "results":
		add_property_editor_for_multiple_properties(
			"Results",
			["results", "weights", "count_ranges"],
			property_script.new(
				plugin,
				{
					"results": object.results,
					"weights": object.weights,
					"count_ranges" : object.count_ranges,
				},
				["Weight", "Min", "Max"],
				[false, true],
				[1.0, Vector2(1, 1)]
			)
		)
		return true

	return false
