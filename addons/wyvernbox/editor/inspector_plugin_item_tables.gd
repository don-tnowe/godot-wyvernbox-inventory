extends EditorInspectorPlugin

var property_script =	load("res://addons/wyvernbox/editor/inspector_item_list.gd")

var plugin

var cur_object_settings := []


func _init(plugin):
	self.plugin = plugin


func _can_handle(object):
	return object.has_method(&"_get_wyvernbox_item_lists")


func _parse_begin(object):
	# Non-tool scripts can't run in editor... unless instantiated in the editor.
	cur_object_settings = []
	if !object.get_script().is_tool():
		object = object.get_script().new()
		if !object is RefCounted:
			object.queue_free()

	cur_object_settings = object._get_wyvernbox_item_lists()


func _parse_property(object, type, path, hint, hint_text, usage, wide):
	for x in cur_object_settings:
		var path_found_at = x[1].find(path)
		if path_found_at == -1:
			# Property not found -> keep looking in other lists.
			continue

		if path_found_at > 0:
			# Property found -> display list only for the first item.
			return true

		# The returned arrays must contain:
		# - Property editor label : String
		# - Array properties edited : Array[String] (the resource array must be first; the folowing props skip the resource array)
		# - Column labels : Array[String] (each vector array must have two/three)
		# - Columns are integer? : bool (each vector array maps to one)
		# - Column default values : Variant
		# - Allowed resource types : Array[Script or Classname]
		var columns_dict := {}
		for y in x[1]:
			columns_dict[y] = object.get(y)

		add_property_editor_for_multiple_properties(
			x[0],
			x[1],
			property_script.new(
				plugin, object, columns_dict,
				x[2],
				x[3],
				x[4],
				x[5],
				x[6] if x.size() >= 7 else []
			)
		)
		return true

	return false
