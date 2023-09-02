extends EditorProperty

enum {
	COMPONENT_X = 0,
	COMPONENT_Y,
	COMPONENT_Z,
	COMPONENT_POS_X = 3,
	COMPONENT_POS_Y,
	COMPONENT_POS_Z,
	COMPONENT_SIZE_X = 6,
	COMPONENT_SIZE_Y,
	COMPONENT_SIZE_Z,
}

var plugin : EditorPlugin
var edited_object : Object

var browse_button := Button.new()
var browse_window : Control
var options_button := Button.new()

var bottom_box := VBoxContainer.new()
var bottom := HBoxContainer.new()
var grid_l := GridContainer.new()
var grid_r := GridContainer.new()

var columns_are_int := []
var allowed_types := []
var columns = {}
var column_defaults = []


func _init(
	plugin : EditorPlugin,
	edited_object : Object,
	columns : Dictionary,
	column_labels : Array,
	columns_int : Array = [],
	column_defaults : Array = [],
	allowed_types : Array = [ItemType],
	allowed_types_string : Array = []
):
	self.columns = columns
	self.plugin = plugin
	self.edited_object = edited_object
	self.allowed_types = allowed_types
	self.column_defaults = column_defaults

	var property_buttons = HBoxContainer.new()
	browse_button.text = "Browse Items..."
	browse_button.flat = true
	browse_button.pressed.connect(_on_browse_pressed)
	browse_button.size_flags_horizontal = SIZE_EXPAND_FILL

	var vis_button = Button.new()
	vis_button.flat = true
	vis_button.pressed.connect(_on_vis_pressed)

	add_child(property_buttons)
	property_buttons.add_child(browse_button)
	property_buttons.add_child(vis_button)
	property_buttons.add_child(load("res://addons/wyvernbox/editor/inspector_item_list_options.gd").new(self))
	add_focusable(browse_button)
	add_focusable(options_button)

	bottom_box.add_child(bottom)
	var picker_cont := HBoxContainer.new()
	var picker_label := Label.new()
	var add_picker := EditorResourcePicker.new()
	picker_label.text = "Add new:"
	picker_cont.add_child(picker_label)
	picker_cont.add_child(add_picker)
	bottom_box.add_child(picker_cont)
	add_picker.size_flags_horizontal = SIZE_EXPAND_FILL
	# add_picker.base_type = ",".join(allowed_types.map(func(x):
	# 	return x.???
	#   # https://github.com/godotengine/godot/issues/21789
	#   # https://github.com/godotengine/godot/pull/80487
	# ))
	if allowed_types_string.size() == 0:
		add_picker.base_type = "ItemLike" if (allowed_types.has(ItemType)) else "Resource"

	else:
		add_picker.base_type = ",".join(allowed_types_string)

	add_child(bottom_box)
	set_bottom_editor(bottom_box)
	add_picker.resource_changed.connect(func(x):
		add_picker.edited_resource = null
		add_item(x)
	)

	grid_l.size_flags_horizontal = SIZE_EXPAND_FILL
	grid_r.size_flags_horizontal = SIZE_EXPAND_FILL
	bottom.add_child(grid_l)
	bottom.add_child(grid_r)

	_ensure_no_empty(column_defaults)
	_init_headers(column_labels)
	_init_items(columns_int)

	await self.ready

	vis_button.icon = get_theme_icon("GuiVisibilityVisible", "EditorIcons")


func _ensure_no_empty(column_defaults):
	var column_arrays = columns.values()
	if column_arrays[0].size() != 0:
		return
	
	column_arrays[0].append(null)
	for i in columns.size() - 1:
		column_arrays[i + 1].append(column_defaults[i])
	
	var column_properties = columns.keys()
	for i in columns.size():
		emit_changed(column_properties[i], column_arrays[i], "", true)


func _can_drop_data(position, data):
	if data.has(&"inspector_item_list_drag_from"):
		return true

	if data.get(&"type", "") != "files":
		return false

	if data.get(&"files", []).size() == 0:
		return false

	return true


func _drop_data(position : Vector2, data):
	if data.has(&"inspector_item_list_drag_from") && data[&"inside_list"] == self:
		move_item(data[&"inspector_item_list_drag_from"], _get_mouseover_item(get_global_mouse_position()))
		return

	for x in data.get("files", []):
		var loaded = load(x)
		for y in allowed_types:
			if instance_has_recursive(loaded, y):
				add_item(loaded)
				break

	for x in data.get("resources", []):
		for y in allowed_types:
			if instance_has_recursive(x, y):
				add_item(x)
				break


static func instance_has_recursive(inst : Object, script : Script) -> bool:
	var cur := inst.get_script()
	while true:
		if cur == script:
			return true

		cur = cur.get_base_script()
		if cur == null:
			return false

	return false


func _gui_input(event : InputEvent):
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		var index_grabbed = _get_mouseover_item(event.global_position)
		if index_grabbed < 0: return
		var drag_preview := grid_l.get_child(grid_l.columns * (index_grabbed + 1) + 1).duplicate()
		drag_preview.clip_text = false
		call_deferred(&"force_drag",
			{&"inspector_item_list_drag_from" : index_grabbed, &"inside_list" : self},
			drag_preview
		)


func _get_mouseover_item(global_pos : Vector2) -> int:
	var icon := grid_l.get_child(grid_l.columns)
	var index := floor((global_pos.y - icon.global_position.y) / (icon.size.y + grid_l.get_theme_constant("v_separation")))
	return mini(index, columns.values()[0].size() - 1)


func add_item(item : Resource):
	var column_properties = columns.keys()
	var column_arrays = columns.values()
	if column_arrays[0][0] == null:
		column_arrays[0][0] = item
		_update_item_in_control(0, item)
		return

	for i in columns.size():
		if i == 0:
			column_arrays[0].append(item)
			_add_item_control(item)

		else:
			column_arrays[i].resize(column_arrays[0].size())
			column_arrays[i][-1] = column_arrays[i][-2]
			_add_cell_control(column_arrays[i][-1], column_properties[i], columns_are_int[i - 1])

		emit_changed(column_properties[i], column_arrays[i], "", true)

	_add_delete_button()


func move_item(from_index : int, to_index : int):
	if from_index < 0 || to_index < 0: return
	for x in columns.values():
		x.insert(to_index, x.pop_at(from_index))

	_clear_items()
	_init_items(columns_are_int)
	for k in columns:
		emit_changed(k, columns[k], "", true)


func remove_item(row_index : int):
	var column_properties = columns.keys()
	var column_arrays = columns.values()
	if column_arrays[0].size() == 1:
		column_arrays[0][0] = null
		_update_item_in_control(0, null)
		emit_changed(column_properties[0], column_arrays[0], "", true)
		return

	for i in grid_l.columns:
		grid_l.get_child((row_index) * grid_l.columns + i).queue_free()

	for i in grid_r.columns:
		grid_r.get_child((row_index) * grid_r.columns + i).queue_free()

	for i in columns.size():
		column_arrays[i].remove_at(row_index - 1)
	
	for i in columns.size():
		emit_changed(column_properties[i], column_arrays[i], "", true)


func _clear_items():
	for x in grid_l.get_children():
		if x.get_index() >= grid_l.columns:
			x.free()

	for x in grid_r.get_children():
		if x.get_index() >= grid_r.columns:
			x.free()


func _add_item_control(item):
	var icon = TextureRect.new()
	icon.expand = true
	grid_l.add_child(icon)

	var label = Label.new()
	# label.mouse_filter = MOUSE_FILTER_PASS
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.clip_text = true
	grid_l.add_child(label)

	icon.custom_minimum_size.x = label.get_minimum_size().y

	var edit_button = Button.new()
	grid_l.add_child(edit_button)
	edit_button.pressed.connect(_on_edit_button_pressed.bind(edit_button))

	grid_l.columns = 3
	_update_item_in_control(grid_l.get_child_count() / grid_l.columns - 2, item)

	if !is_inside_tree():
		# Only inherits theme if has a parent <= is in tree
		await self.ready

	edit_button.icon = get_theme_icon("Edit", "EditorIcons")


func _update_item_in_control(row_index, item):
	if item == null:
		item = ItemType.new()
		item.resource_name = "[use input]" if edited_object is ItemGenerator else "[any item]" if edited_object is ItemPattern else "[empty]"
		item.texture = null

	var icon = grid_l.get_child((row_index + 1) * grid_l.columns)
	icon.texture = item.texture

	var label = grid_l.get_child((row_index + 1) * grid_l.columns + 1)
	if item.resource_name == "":
		if _resource_is_local(item.resource_path):
			label.text = "New " + ("Generator" if item is ItemGenerator else "Pattern")

		else:
			label.text = item.resource_path.get_file().get_basename()

	else:
		label.text = item.resource_name

	label.tooltip_text = item.resource_path
	if item is ItemGenerator:
		label.modulate = Color.GOLD

	if item is ItemPattern:
		label.modulate = Color.DARK_TURQUOISE


func _resource_is_local(path):
	return (
		path == ""
		|| (edited_object is Resource && path.left(path.rfind("::")) == edited_object.resource_path)
		|| (edited_object is Node && edited_object.owner != null && path.left(path.rfind("::")) == edited_object.owner.scene_file_path)
	)


func _add_cell_control(value, property_name, is_int = false, vec_component = -1):
	if value is Vector2:
		_add_cell_control(value.x, property_name, is_int, COMPONENT_X)
		_add_cell_control(value.y, property_name, is_int, COMPONENT_Y)
		return

	elif value is Vector3:
		_add_cell_control(value.x, property_name, is_int, COMPONENT_X)
		_add_cell_control(value.y, property_name, is_int, COMPONENT_Y)
		_add_cell_control(value.z, property_name, is_int, COMPONENT_Z)
		return

	elif value is Rect2:
		_add_cell_control(value.position.x, property_name, is_int, COMPONENT_POS_X)
		_add_cell_control(value.position.y, property_name, is_int, COMPONENT_POS_Y)
		_add_cell_control(value.size.x, property_name, is_int, COMPONENT_SIZE_X)
		_add_cell_control(value.size.y, property_name, is_int, COMPONENT_SIZE_Y)
		return

	var slider = EditorSpinSlider.new()
	slider.step = 1.0 if is_int else 0.01
	slider.allow_greater = true
	slider.hide_slider = true
	slider.max_value = 999999999.9
	slider.custom_minimum_size.x = 48.0
	slider.size_flags_horizontal = SIZE_EXPAND_FILL

	slider.value = value
	grid_r.add_child(slider)
	add_focusable(slider)

	slider.value_changed.connect(_on_cell_value_edited.bind(
		slider,
		property_name,
		vec_component,
	))


func _add_delete_button():
	var button = Button.new()
	grid_r.add_child(button)
	button.pressed.connect(_on_delete_button_pressed.bind(button))
	if !is_inside_tree():
		await self.ready

	button.icon = get_theme_icon("Remove", "EditorIcons")


func _init_headers(column_labels):
	var label := Button.new()
	label.text = "Item"
	label.disabled = true
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.alignment = HORIZONTAL_ALIGNMENT_LEFT
	grid_l.add_child(Control.new())
	grid_l.add_child(label)
	grid_l.add_child(Control.new())
	for x in column_labels:
		label = Button.new()
		label.text = x
		label.disabled = true
		label.mouse_filter = MOUSE_FILTER_IGNORE
		label.alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid_r.add_child(label)

	grid_r.add_child(Control.new())


func _init_items(columns_int : Array):
	if columns_int.size() < columns.size() - 1:
		columns_int.resize(columns.size())
		columns_int.fill(false)

	columns_are_int = columns_int
	var column_keys = columns.keys()
	var column_arrays = columns.values()
	for i in column_arrays.size():
		if column_arrays[i] == null:
			column_arrays[i] = []
			columns[column_keys[i]] = column_arrays[i]
			emit_changed(column_keys[i], column_arrays[i], "", false)

		for j in column_arrays[0].size() - column_arrays[i].size():
			column_arrays[i].append(column_defaults[i - 1])

	_init_column_count(columns)
	for i in column_arrays[0].size():
		for j in columns.size():
			if j == 0:
				_add_item_control(column_arrays[0][i])

			else:
				_add_cell_control(
					column_arrays[j][i] if column_arrays[j][i] != null else column_defaults[j - 1],
					column_keys[j],
					columns_int[j - 1]
				)

		_add_delete_button()


func _init_column_count(columns):
	var column_count = 1
	var value
	var arrays = columns.values()
	for i in columns.size():
		value = arrays[i][0]
		if value == null:
			if i == 0:
				continue

			value = column_defaults[i - 1]

		if value is Object:
			continue

		if value is Vector2:
			column_count += 2

		elif value is Vector3:
			column_count += 3

		elif value is Rect2:
			column_count += 4

		else:
			column_count += 1

	grid_r.columns = column_count


func _on_delete_button_pressed(button):
	remove_item(button.get_index() / grid_r.columns)


func _on_cell_value_edited(new_value : int, cell, property_name, vec_component = -1):
	var row_index = cell.get_index() / grid_r.columns - 1
	var column_array = columns[property_name]
	match vec_component:
		-1:
			column_array[row_index] = new_value

		COMPONENT_X:
			column_array[row_index].x = new_value

		COMPONENT_Y:
			column_array[row_index].y = new_value

		COMPONENT_Z:
			column_array[row_index].z = new_value

	emit_changed(property_name, column_array, "", true)


func _on_edit_button_pressed(button):
	var edit_resource = button.get_index() / grid_l.columns - 1
	plugin.get_editor_interface().call_deferred("edit_resource", columns.values()[0][edit_resource])


func _on_browse_pressed():
	if browse_window == null:
		browse_window = load("res://addons/wyvernbox/editor/item_browser.tscn").instantiate()
		browse_button.add_child(browse_window)
		await get_tree().process_frame
		browse_window.initialize(plugin, allowed_types)
		browse_window.hide()

	await get_tree().process_frame
	browse_window.top_level = true
	browse_window.visible = !browse_window.visible
	browse_window.global_position = Vector2(
		get_node("../../../..").global_position.x - browse_window.size.x - 8.0,
		global_position.y
	)


func _on_vis_pressed():
	bottom.visible = !bottom.visible
	get_child(0).get_child(1).icon = get_theme_icon("GuiVisibilityVisible" if bottom.visible else "GuiVisibilityHidden", "EditorIcons")
