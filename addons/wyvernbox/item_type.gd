@tool
@icon("res://addons/wyvernbox/icons/item_type.png")
class_name ItemType
extends ItemLike

## A template for an item.
##
## Write [code]ItemStack.new(this_item_type, count)[/code] to create an item that can be inserted into an [Inventory], or used for other purposes.

enum SlotFlags {
	SMALL = 1 << 0,
	LARGE = 1 << 1,
	EQUIPMENT = 1 << 2,
	QUEST = 1 << 3,
	POTION = 1 << 4,
	AMMO = 1 << 5,
	CURRENCY = 1 << 6,
	FUEL = 1 << 7,
	KEY = 1 << 8,
	CRAFTING = 1 << 9,
	#
	#
	#
	#
	#
	#
	E_MAINHAND = 1 << 16,
	E_OFFHAND = 1 << 17,
	E_HEAD = 1 << 18,
	E_CHEST = 1 << 19,
	E_BELT = 1 << 20,
	E_HANDS = 1 << 21,
	E_FEET = 1 << 22,
	E_RING = 1 << 23,
	E_NECK = 1 << 24,
}
## Matches flags of all equipment slots (hands, helmet, chest, belt, handwear, footwear, ring and neck)
const EQUIPMENT_FLAGS := (
	SlotFlags.E_MAINHAND
	| SlotFlags.E_OFFHAND
	| SlotFlags.E_HEAD
	| SlotFlags.E_CHEST
	| SlotFlags.E_BELT
	| SlotFlags.E_HANDS
	| SlotFlags.E_FEET
	| SlotFlags.E_RING
	| SlotFlags.E_NECK
)
## The item's name. Can be a locale string.
@export var name := ""

## The item's description. Can be empty or a locale string.
@export_multiline var description := ""

## Tags, for any custom purpose.
@export var tags : Array[StringName]

## The item's texture.
@export var texture : Texture2D:
	set(v):
		texture = v
		notify_property_list_changed()

## The scale of the item's texture.
@export var texture_scale := 1.0

@export_group("Inventory Space")
## How many items can fit into a single stack.
@export var max_stack_count := 1

## How many cells, horizontally, this item occupies in a [GridInventory].
@export var in_inventory_width := 1

## How many cells, vertically, this item occupies in a [GridInventory].
@export var in_inventory_height := 1

## The [enum SlotFlags] of this item. Used in [RestrictedInventory].
@export_flags(
"SMALL",
"LARGE",
"EQUIPMENT",
"QUEST",
"POTION",
"AMMO",
"CURRENCY",
"FUEL",
"KEY",
"CRAFTING",
"#",
"#",
"#",
"#",
"#",
"#",
"E_MAINHAND",
"E_OFFHAND",
"E_HEAD",
"E_CHEST",
"E_BELT",
"E_HANDS",
"E_FEET",
"E_RING",
"E_NECK",
	) var slot_flags := 1

@export_group("Other")
## The [Mesh] to spawn when it gets created on the ground. If not set, shows [member Texture].
@export var mesh : Mesh

## Optionally, the [PackedScene] to spawn when it gets created on the ground.
## If not set, uses scene set in [GroundItemManager] with [member mesh] or [member texture].
@export var custom_ground_prefab : PackedScene

## The string representation of the type's [member default_properties].
@export_multiline var default_properties_string : String:
	set(v):
		default_properties_string = v
		if default_properties_converting: return
		default_properties_converting = true
		var converted = str_to_var(v)
		if converted is Dictionary: default_properties = converted
		default_properties_converting = false

## The type's default property dictionary. [br]
## For editing, [default_properties_string] or the Dictionary Inspector addon are recommended. [br]
## Can contain various data for display in [InventoryTooltip] via its [InventoryTooltipProperty], or other, game-specific uses. [br]
## [code]price[/code] is used for vendor prices, selling and buying. [br]
## [code]back_color[/code] is used to show a colored background in inventories and a glow on the ground. [br]
## For more, edit an [ItemType] with the plugin enabled and search the inspector.
@export var default_properties : Dictionary:
	set(v):
		default_properties = v
		if default_properties_converting: return
		default_properties_converting = true
		default_properties_string = var_to_str(default_properties)
		default_properties_converting = false

var default_properties_converting := false


## Returns [member in_inventory_width] and [member in_inventory_height] as a [code]Vector2[/code].
func get_size_in_inventory() -> Vector2:
	return Vector2(in_inventory_width, in_inventory_height)

## Returns [code]true[/code] if stack has the same type.
## For compatibility with [method ItemPattern.matches].
func matches(stack) -> bool:
	return stack.item_type == self

## Returns the value it contributes to an [ItemConversion]. Equals to the stack's [member ItemStack.count].
## For compatibility with [method ItemPattern.get_value].
func get_value(stack) -> int:
	return stack.count
