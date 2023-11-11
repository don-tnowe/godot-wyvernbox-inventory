extends EditorInspectorPlugin

const FLAG_VIEW_CELL_SIZE := Vector2(17, 17)
const BUILTIN_EXTRAS := [
	[&"back_color", "Color", Color.WHITE, "The color associated with the item.\nAffects ItemStackView's background, Tooltip title background, and GroundItemStackView glow."],
	[&"price", "Dict[String path : int]", {}, "The items ([i]and their amounts[/i]) needed to buy the item from vendors or sell it.\n[b]Note:[/b] Can be an ItemType Resource from the project files, but internally, Wyvernbox stores prices as path strings."],
	[&"stats", "Dict[StringName : float]", {}, "Stat bonuses added by the item. Recommended to append a character at the end to use with Wyvernshield's [b]set_suffixed()[/b] method:\n \"health+\" will add to the base value of health, \"health%\" to additive multiplier, \"health*\" to multiplicatively stacking multiplier"],
	[&"name", "Array[String]", ["", null, ""], "Default name override. Includes all affixes. The null-value gets replaces by the default name."],
	[&"custom_texture", "Variant", "res://", "Texture override.[br]- If String, loads from specified path.[br]- If Dictionary, loads it like an Image's [code]data[/code] property.[br]- If Array, displays each non-null element of the array on top of each other - see above."],
	[&"texture_colors", "Array[Color]", [Color.WHITE], "Color overrides.[br]If no [code]custom_texture[/code], should be an array with one color. If [code]custom_texture[/code] is present and is an array, each item must match a color here."],
]

var plugin


func _init(plugin):
	self.plugin = plugin


func _can_handle(object):
	return object is ItemType


func _parse_property(object : Object, type, path : String, hint, hint_text : String, usage : int, wide : bool):
	match path:
		"texture":
			var new_prop := EditorProperty.new()
			var new_slider := EditorSpinSlider.new()
			new_prop.label = "Texture Frame"
			new_prop.tooltip_text = "For [AtlasTexture], change this to easily modify the grid cell region displayed."
			new_prop.add_child(new_slider)
			new_slider.tooltip_text = new_prop.tooltip_text
			new_slider.min_value = 0
			new_slider.visible = object.texture is AtlasTexture
			if object.texture is AtlasTexture && object.texture.atlas != null:
				var rect : Rect2 = object.texture.region
				var hframes : int = object.texture.atlas.get_size().x / rect.size.x
				new_slider.value = (rect.position.x / rect.size.x) + floor(rect.position.y / rect.size.y) * hframes
				new_slider.max_value = hframes * object.texture.atlas.get_size().y / rect.size.y

			new_slider.value_changed.connect(_on_texture_frame_value_changed.bind(object))
			add_custom_control(new_prop)
			(func(): new_prop.get_parent().move_child(new_prop, new_prop.get_index() + 1)).call_deferred()
			return false

		"slot_flags":
			var new_prop := EditorProperty.new()
			var new_flag_view := Control.new()
			var new_label := Label.new()
			new_flag_view.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
			new_flag_view.custom_minimum_size = Vector2(
				FLAG_VIEW_CELL_SIZE.x * 16 - 1,
				FLAG_VIEW_CELL_SIZE.y * 2 - 1,
			)
			new_label.clip_text = true
			new_prop.add_child(new_label)
			new_prop.add_child(new_flag_view)
			new_prop.set_bottom_editor(new_flag_view)
			new_flag_view.gui_input.connect(_on_slot_flags_gui_input.bind(new_flag_view, object, new_label))
			new_flag_view.mouse_exited.connect(_on_slot_flags_mouse_exited.bind(new_flag_view, object, new_label))
			new_flag_view.draw.connect(_on_slot_flags_draw.bind(new_flag_view, object, new_label))
			add_property_editor("slot_flags", new_prop)
			_on_slot_flags_mouse_exited(new_flag_view, object, new_label)
			return true

		"default_properties":
			var new_prop := VBoxContainer.new()
			var new_button := Button.new()
			var new_desc := RichTextLabel.new()
			new_button.text = "⚠More on properties..."
			new_desc.hide()
			new_desc.fit_content = true
			new_desc.append_text("")

			var result_desc := ["Items can store properties of any non-Object type - they can be accessed from the ItemStack's [code]extra_properties[/code] property.\nClick keys below to add properties to this item.\ndefault_properties_string mirrors default_properties both ways, edit whichever you like.\n"]
			for i in BUILTIN_EXTRAS.size():
				result_desc.append("[b][url=%s]%s[/url] : %s[/b]\n%s\n" % [i, BUILTIN_EXTRAS[i][0], BUILTIN_EXTRAS[i][1], BUILTIN_EXTRAS[i][3]])

			new_desc.append_text("\n".join(result_desc))

			new_prop.add_child(new_button)
			new_prop.add_child(new_desc)
			add_custom_control(new_prop)
			new_button.pressed.connect(func(): new_desc.visible = !new_desc.visible)
			var meta_clicked_callback = _on_extra_description_meta_clicked
			(func(): new_desc.meta_clicked.connect(
				meta_clicked_callback.bind(
					object,
					new_prop.get_parent().get_child(new_prop.get_index() - 1)
				)
			)).call_deferred()
			return false


func _on_texture_frame_value_changed(new_value : float, object : Object):
	if object.texture is AtlasTexture:
		var rect : Rect2 = object.texture.region
		var hframes : int = object.texture.atlas.get_size().x / rect.size.x
		object.texture.region.position = Vector2(
			(int(new_value) % hframes) * rect.size.x,
			floor(new_value / hframes) * rect.size.y,
		)


func _on_slot_flags_draw(flag_view : Control, object : Object, label : Label):
	var mouse_pos := flag_view.get_local_mouse_position()
	var mouse_cell := -1 if !Rect2(Vector2.ZERO, flag_view.size).has_point(mouse_pos) else _get_slot_flags_mouse_cell(mouse_pos)
	var object_slot_flags : int = object.slot_flags

	var theme_font := flag_view.get_theme_font(&"normal", &"Label")
	var theme_font_size := flag_view.get_theme_default_font_size()

	for i in 32:
		var flag_on := object_slot_flags & 1 << i != 0
		var color_a := (0.5 if mouse_cell == i else 0.1) + (0.4 if (flag_on) else 0.0)
		flag_view.draw_rect(Rect2(Vector2(i % 16, i / 16) * FLAG_VIEW_CELL_SIZE, FLAG_VIEW_CELL_SIZE - Vector2.ONE), Color(1, 1, 1, color_a))
		if flag_on:
			var key = ItemType.SlotFlags.find_key(1 << i)
			if !key: key = " "
			theme_font.draw_char(
				flag_view.get_canvas_item(),
				Vector2(i % 16, i / 16) * FLAG_VIEW_CELL_SIZE + theme_font.get_char_size(key.unicode_at(0), theme_font_size),
				key.unicode_at(0),
				theme_font_size,
				Color.BLACK,
			)


func _on_slot_flags_gui_input(event : InputEvent, flag_view : Control, object : Object, label : Label):
	var mouse_pos := flag_view.get_local_mouse_position()
	if event is InputEventMouseMotion:
		var flag := _get_slot_flags_mouse_cell(mouse_pos)
		var found_key = ItemType.SlotFlags.find_key(1 << flag)
		if !found_key:
			label.text = "?:%s" % [flag]

		else:
			label.text = "%s:%s" % [found_key, flag]

	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
		var toggled_cell = _get_slot_flags_mouse_cell(mouse_pos)
		object.slot_flags ^= 1 << toggled_cell
		flag_view.get_parent().emit_changed("slot_flags", object.slot_flags)

	flag_view.queue_redraw()


func _on_slot_flags_mouse_exited(flag_view : Control, object : Object, label : Label):
	var flags_on = []
	var object_slot_flags : int = object.slot_flags
	for k in ItemType.SlotFlags:
		if object_slot_flags & ItemType.SlotFlags[k] != 0:
			flags_on.append(k.capitalize())

	label.text = ", ".join(flags_on)
	label.tooltip_text = label.text
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	flag_view.queue_redraw()


func _get_slot_flags_mouse_cell(mouse_pos : Vector2) -> int:
	return floor(mouse_pos.x / FLAG_VIEW_CELL_SIZE.x) + floor(mouse_pos.y / FLAG_VIEW_CELL_SIZE.y) * 16.0


func _on_extra_description_meta_clicked(meta : String, object : Object, prop_editor : EditorProperty):
	var builtin_prop_info : Array = BUILTIN_EXTRAS[meta.to_int()]
	var item_extras : Dictionary = object.default_properties
	if !item_extras.has(builtin_prop_info[0]):
		item_extras[builtin_prop_info[0]] = builtin_prop_info[2]

	prop_editor.emit_changed(&"default_properties", item_extras)
