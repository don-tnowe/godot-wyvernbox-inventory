@tool
extends EditorPlugin

const scripts_dir := "res://addons/wyvernbox/"
const icons_dir := "res://addons/wyvernbox/icons"

var added_scripts := [
	[
		"InventoryView",
		preload(scripts_dir + "inventory_view.gd"),
		icons_dir + "inventory_view.png",
	],
	[
		"EquipBonus",
		preload(scripts_dir + "equip_bonus.gd"),
		icons_dir + "equip_bonus.png",
	],
	[
		"ItemInstantiator",
		preload(scripts_dir + "item_instantiator.gd"),
		icons_dir + "item_instantiator.png",
	],
	[
		"GrabbedItemStack",
		preload(scripts_dir + "view_extra/grabbed_item_stack.gd"),
		icons_dir + "grabbed_item_stack.png",
	],
	[
		"ItemStackView",
		preload(scripts_dir + "view_extra/item_stack_view.gd"),
		icons_dir + "item_stack_view.png",
	],
	[
		"InventoryTooltip",
		preload(scripts_dir + "view_extra/tooltip.gd"),
		icons_dir + "tooltip.png",
	],
	[
		"TooltipProperty",
		preload(scripts_dir + "view_extra/tooltip_property.gd"),
		icons_dir + "tooltip_property.png",
	],
	[
		"InventoryVendor",
		preload(scripts_dir + "crafting/vendor.gd"),
		icons_dir + "vendor.png",
	],
	# --- ITEMLIKES ---
	[
		"ItemType",
		preload(scripts_dir + "item_type.gd"),
		icons_dir + "item_type.png",
	],
	[
		"ItemPattern",
		preload(scripts_dir + "crafting/item_pattern.gd"),
		icons_dir + "item_pattern.png",
	],
	[
		"ItemGenerator",
		preload(scripts_dir + "crafting/item_generator.gd"),
		icons_dir + "item_generator.png",
	],
	[
		"ItemConversion",
		preload(scripts_dir + "crafting/item_conversion.gd"),
		icons_dir + "item_conversion.png",
	],
	# --- ITEMLIKES : EXTRA ---
	[
		"ItemGeneratorEquipmentBonus",
		preload(scripts_dir + "extension/item_generator_equipment_bonus.gd"),
		icons_dir + "item_generator.png",
	],
	[
		"ItemPatternEquipStat",
		preload(scripts_dir + "extension/item_pattern_equip_stat.gd"),
		icons_dir + "item_pattern.png",
	],
	[
		"ItemPatternHighlightStack",
		preload(scripts_dir + "extension/item_pattern_highlight_stack.gd"),
		icons_dir + "item_pattern.png",
	],
	[
		"ItemPatternName",
		preload(scripts_dir + "extension/item_pattern_name.gd"),
		icons_dir + "item_pattern.png",
	],
	# --- INVENTORIES ---
	[
		"Inventory",
		preload(scripts_dir + "inventories/inventory.gd"),
		icons_dir + "inventory.png",
	],
	[
		"GridInventory",
		preload(scripts_dir + "inventories/grid_inventory.gd"),
		icons_dir + "grid_inventory.png",
	],
	[
		"CurrencyInventory",
		preload(scripts_dir + "inventories/currency_inventory.gd"),
		icons_dir + "currency_inventory.png",
	],
	[
		"RestrictedInventory",
		preload(scripts_dir + "inventories/restricted_inventory.gd"),
		icons_dir + "restricted_inventory.png",
	],
	# --- GROUND ---
	[
		"GroundItemsManager",
		preload(scripts_dir + "ground/ground_items_manager.gd"),
		icons_dir + "ground_items_manager.png",
	],
	[
		"GroundItemStackView2D",
		preload(scripts_dir + "ground/ground_item_stack_view_2d.gd"),
		icons_dir + "ground_item_stack_view_2d.png",
	],
	[
		"GroundItemStackView3D",
		preload(scripts_dir + "ground/ground_item_stack_view_3d.gd"),
		icons_dir + "ground_item_stack_view_3d.png",
	],
]


var inspector_plugins = [
	load("res://addons/wyvernbox/editor/inspector_plugin_item_tables.gd").new(self),
	load("res://addons/wyvernbox/editor/inspector_plugin_item_type.gd").new(self),
]


func _enter_tree():
	var editor_base_node := get_editor_interface().get_base_control()
	for x in inspector_plugins:
		add_inspector_plugin(x)

	for x in added_scripts:
		var x_icon = x[2]
		if x_icon == null:
			x_icon = x[1].get_instance_base_type()

		if x_icon is StringName || x_icon is String:
			x_icon = editor_base_node.get_theme_icon(x_icon, "EditorIcons")

		add_custom_type(x[0], x[1].get_instance_base_type(), x[1], x_icon)

	initialize_setting("input/menu_inventory", {
		"deadzone" : 0.2,
		"events" : [
			create_input_event(InputEventKey, KEY_TAB),
			create_input_event(InputEventKey, KEY_I),
			create_input_event(InputEventJoypadButton, JOY_BUTTON_BACK),
		]
	})
	initialize_setting("input/inventory_less", {
		"deadzone" : 0.01,
		"events" : [
			create_input_event(InputEventKey, KEY_ALT),
			create_input_event(InputEventJoypadButton, JOY_BUTTON_LEFT_SHOULDER),
		]
	})
	initialize_setting("input/inventory_more", {
		"deadzone" : 0.01,
		"events" : [
			create_input_event(InputEventKey, KEY_SHIFT),
			create_input_event(InputEventJoypadButton, JOY_BUTTON_RIGHT_SHOULDER),
		]
	})
	initialize_setting("input/inventory_filter", {
		"deadzone" : 0.01,
		"events" : [
			create_input_event(InputEventKey, KEY_F),
			create_input_event(InputEventJoypadButton, JOY_BUTTON_Y),
		]
	})


func _exit_tree():
	for x in inspector_plugins:
		remove_inspector_plugin(x)

	for x in added_scripts:
		remove_custom_type(x[0])


func initialize_setting(key, value):
	if !ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, value)


func create_input_event(event_type, input_index):
	var event = event_type.new()
	if event_type == InputEventKey: event.keycode = input_index
	if event_type == InputEventMouse: event.button_index = input_index
	if event_type == InputEventJoypadButton: event.button_index = input_index
	if event_type == InputEventJoypadMotion: event.axis = input_index
	return event
