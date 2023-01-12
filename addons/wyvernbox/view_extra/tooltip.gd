class_name InventoryTooltip, "res://addons/wyvernbox/icons/tooltip.png"
extends Container

const ITEM_SCALE := 0.5

export var compare_input := "inventory_more"
export var filter_input := "inventory_filter"
export var clear_filter_mod_input := "inventory_less"

export var color_bonus := Color.yellow
export var color_malus := Color.red
export var color_neutral := Color.darkgray
export var color_description := Color.white
export var compare_to_inventory : NodePath

export(Array, Script) var property_scripts

var last_func : FuncRef
var last_func_args : Array
var ground_item_state := 0  # 0 for none, 1 for hovering, 2 for released

# Empties the display. Called before the tooltip must display something.
func display_empty():
	$"%Title/..".self_modulate = Color.white
	$"%Desc".bbcode_text = ""
	for x in get_node("Box").get_children():
		if x.get_position_in_parent() > 1:
			x.free()

	show()

# Displays an item's name and calls all `property_scripts` display methods.
# `mouseover_node` is the `Control` this tooltip must be placed next to.
func display_item(item_stack : ItemStack, mouseover_node : Control, shown_from_inventory : bool = true):
	if shown_from_inventory:
		ground_item_state = 0
	
	else:
		ground_item_state = 1

	if mouseover_node == null:
		hide()
		return
	
	display_empty()
	$"%Title".text = item_stack.get_name()
	$"%Title/..".self_modulate = Color.white.blend(item_stack.extra_properties.get("back_color", Color.gray)) * 2.0
	
	var bbcode_label = $"%Desc"
	bbcode_label.bbcode_text = "[center]"

	var property_instance
	var last_label = bbcode_label
	for x in property_scripts:
		property_instance = x.new()
		property_instance.tooltip = self
		property_instance._tooltip_last_label = last_label
		property_instance._display(item_stack)
		last_label = property_instance._tooltip_last_label

	_update_rect(mouseover_node)
	last_func = funcref(self, "display_item")
	last_func_args = [item_stack, mouseover_node, shown_from_inventory]
	call_deferred("_update_rect", mouseover_node)

# Displays the name and description of an `EquipBonus`.
# `node` is the `Control` this tooltip must be placed next to.
func display_bonus(node : Control, bonus_res : Resource):
	var desc = tr("item_bonus_desc_" + bonus_res.id)
	if desc == "item_bonus_desc_" + bonus_res.id:
		desc = ""
	
	display_custom(
		node,
		tr("item_bonus_" + bonus_res.id),
		"[center]\n" + desc + "\n\n"
		+ tr("item_tt_tutorial_filter_bonus") % get_action_bbcode(filter_input)
	)

	last_func = funcref(self, "display_bonus")
	last_func_args = [node, bonus_res]

# Custom display of a title and a rich text description.
# `mouseover_node` is the `Control` this tooltip must be placed next to.
func display_custom(mouseover_node : Control, title : String, bbcode_description : String):
	display_empty()
	$"%Title".text = title
	$"%Desc".bbcode_text = bbcode_description

	_update_rect(mouseover_node)
	last_func = funcref(self, "display_custom")
	last_func_args = [mouseover_node, title, bbcode_description]
	call_deferred("_update_rect", mouseover_node)

# Shows the tooltip again after hidden, with the same contents.
func display_last():
	if last_func != null:
		last_func.call_funcv(last_func_args)

# Returns the visual representation of an `InputEvent` of the specified `action`.
func get_action_bbcode(action : String) -> String:
	# TODO: detect when there is a joystick input and show that
	for x in InputMap.get_action_list(action):
		if x is InputEventKey:
			return "[color=#aaa]%s[/color]" % x.as_text()

	return "[color=#aaa]%s[/color]" % action.capitalize()

# Turns a dictionary of stat bonuses or differences into rich text.
# `hex_bonus`, `hex_neutral` and `hex_malus` are used for added stats, zeroes, and reduced stats.
static func get_stats_bbcode(displayed_stats : Dictionary, hex_bonus : String, hex_neutral : String, hex_malus : String) -> String:
	var first := true
	var value := 0.0
	var text := ""
	for k in displayed_stats:
		first = true
		for i in displayed_stats[k].size():
			value = displayed_stats[k][i]
			text += ("%s[color=#%s]%s%s" % [
				("" if first else "/"),
				(hex_bonus if value > 0.0 else (hex_neutral if value == -0.0 else hex_malus)),
				("+" if value >= 0.0 else ""),
				value
			])
			first = false
		
		text += (
			" "
			+ TranslationServer.translate("item_bonus_" + k)
			+ "[/color]\n"
		)

	return text

# Turns a `Texture` into rich text.
# Allows to specify scale. For a fixed height, see `get_fixheight_texture_bbcode`.
static func get_texture_bbcode(tex_path : String, tex_scale : float = 1.0) -> String:
	var loaded = load(tex_path)
	if loaded == null: return ""
	return "[img=%sx%s]%s[/img]" % [
		loaded.get_width() * tex_scale * ITEM_SCALE,
		loaded.get_height() * tex_scale * ITEM_SCALE,
		tex_path,
	]

# Turns a `Texture` into rich text.
# Allows to specify a fixed height, in pixels. For a fixed pixel size, see `get_texture_bbcode`.
static func get_fixheight_texture_bbcode(tex_path : String, tex_height : float) -> String:
	var loaded = load(tex_path)
	if loaded == null: return ""
	var tex_scale = loaded.get_height() / tex_height
	return "[img=%sx%s]%s[/img]" % [
		loaded.get_width() * tex_scale,
		loaded.get_height() * tex_scale,
		tex_path,
	]


func _update_rect(mouseover_node):
	var left = mouseover_node.rect_global_position.x + mouseover_node.rect_size.x * 0.5 < get_viewport_rect().size.x * 0.5
	rect_size = Vector2.ZERO
	rect_position = mouseover_node.rect_global_position + Vector2(
		(mouseover_node.rect_size.x if left else -rect_size.x),
		(mouseover_node.rect_size.y - rect_size.y) * 0.5
	)
	rect_position.y = clamp(rect_position.y, 0,  get_viewport_rect().size.y - rect_size.y)


func _input(event):
	if event.is_action(filter_input) && event.is_pressed():
		if Input.is_action_pressed(clear_filter_mod_input):
			for x in get_tree().get_nodes_in_group("view_filterable"):
				x.view_filter_patterns = []

			return

		_apply_filter_to_inventories()

	if event.is_action(compare_input):
		if ground_item_state == 1:
			if !event.is_pressed(): hide()
			else: display_last()

		elif ground_item_state == 2:
			ground_item_state = 0
			hide()

		elif visible:
			display_last()


func _apply_filter_to_inventories():
	var patterns = _get_filter_to_apply()
	for x in get_tree().get_nodes_in_group("view_filterable"):
		x.view_filter_patterns = patterns


func _get_filter_to_apply():
	if last_func == null: return []

	if last_func.function == "display_bonus":
		return [ItemPatternEquipStat.new([], [], [last_func_args[1].id])]

	if last_func.function != "display_item": return []
	var item_stack = last_func_args[0]

	if Input.is_action_pressed(compare_input) && item_stack.extra_properties.has("price"):
		var price_items = item_stack.extra_properties["price"].keys()
		for i in price_items.size():
			price_items[i] = load(price_items[i])

		return [ItemPatternHighlightStack.new(price_items, [], item_stack)]

	else:
		return [ItemPattern.new([item_stack.item_type])]


func _on_ground_item_released():
	ground_item_state = 2
