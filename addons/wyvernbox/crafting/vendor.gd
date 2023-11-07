@tool
@icon("res://addons/wyvernbox/icons/vendor.png")
class_name InventoryVendor
extends Node

## I provide services on selling wares you give me! Give me an [InventoryView] and I shall bring you the [ItemStack]s taken right from adventurers' inventories.

## Emitted when one gives me an item, and I gladly accept before granting a reward. After this, it's mine to sell!
signal item_received(item_stack : ItemStack)
## Emitted when one asks for an item and I gladly provide, after I put up another for sale.
signal item_given(item_stack : ItemStack)
## Emitted when one asks for an item, but need to be a little richer!
signal item_cant_afford(item_stack : ItemStack)

## The [InventoryView] I can place my stock into! Must use the VENDOR [enum InventoryView.InteractionFlags].
@export var vendor_inventory := NodePath()

## The [InventoryView] where I can place the price of items I receive!
@export var sell_reward_into_inventory := NodePath()

## How expensive and prestige my wares are! [br]
## Price will be from the item's [code]&"price"[/br] extra property multiplied by this.
@export var price_markup := 2.0

## Apply this [ItemGenerator] to all of my stock!
@export var apply_to_all_stock : ItemGenerator

## My precious wares that your player can buy!
@export var stock : Array[ItemLike]:
	set = _set_stock

## The amount of each item I sell at once.
@export var stock_counts : Array[int]:
	set = _set_stock_counts

## The number of times your Player can buy each of my items! (1 for single-time purchase)
@export var stock_restocks : Array[int]:
	set = _set_stock_restocks


## If set, I can bring unlimited supplies of my wares! (if one has enough coin to buy them, thet is!)
@export var infinite_restocks := true

## If set, I will remove the price tag off my items, so they can not be re-sold anywhere!
@export var remove_price_on_buy := false

## If set, items the Player sells me will be gone forever once they look away! (or my parent node becomes invisible) [br]
## [method clear_sold_items] can be called manually to clear on demand.
@export var clear_sold_items_when_hidden := true

## If set, my [member price_markup] will not get applied to items the Player sells to me!
@export var free_buyback := true


## The [RandomNumberGenerator] used by my intricate [ItemGenerator]s!
var rng = RandomNumberGenerator.new()


func _set_stock(v):
	stock = v
	_resize_arrays(v.size())


func _set_stock_counts(v):
	stock_counts = v
	_resize_arrays(v.size())


func _set_stock_restocks(v):
	stock_restocks = v
	_resize_arrays(v.size())


func _resize_arrays(size):
	stock_restocks.resize(size)
	stock_counts.resize(size)
	stock.resize(size)


func _ready():
	if Engine.is_editor_hint(): return

	rng.randomize()
	refill_stock()
	get_parent().connect("visibility_changed", Callable(self, "_on_visibility_changed"))

## Replenishes the inventory's contents with fresh stock from get_stock.
func refill_stock():
	var inventory = get_node(vendor_inventory).inventory
	for x in inventory.items:
		inventory.remove(x)

	for i in stock.size():
		var stack = get_stock(i)
		_put_up_for_sale(stack, inventory, i)
		inventory.try_add_item(stack)

## Returns stack with type from [member stock] with count [member stock_counts] purchasable [member stock_restocks] + 1 times.
## If it's an [ItemGenerator], adds first output stack of that.
## If [member apply_to_all_stock] set, always applies that.
func get_stock(index : int) -> ItemStack:
	var stack
	if stock[index] is ItemGenerator:
		stack = stock[index].get_items(rng)[0]
		stack.count *= stock_counts[index]

	else:
		stack = ItemStack.new(stock[index], stock_counts[index], stock[index].default_properties.duplicate(true))

	if apply_to_all_stock != null:
		return apply_to_all_stock.get_items(rng, [stack], [stack.item_type])[0]

	return stack

## Clears all items placed here by the player.
## If [member clear_sold_items_when_hidden], gets called automatically when the parent [CanvasItem] gets hidden.
func clear_sold_items():
	var inventory = get_node(vendor_inventory).inventory
	for x in inventory.items.duplicate():
		if x.extra_properties["seller_stash_index"] == -1:
			inventory.remove_item(x)

## Must return settings for displays of item lists. Override to change behaviour, or add to your own class.
## The returned arrays must contain:
## - Property editor label : String
## - Array properties edited : Array[String] (the resource array must be first; the folowing props skip the resource array)
## - Column labels : Array[String] (each vector array must have two/three)
## - Columns are integer? : bool (each vector array map to one)
## - Column default values : Variant
## - Allowed resource types : Array[Script or Classname]
func _get_wyvernbox_item_lists() -> Array:
	return [[
		"Stock", ["stock", "stock_counts", "stock_restocks"],
		["Count", "Restocks"], [true, true], [1, 0],
		[ItemType, ItemGenerator], ["ItemType", "ItemGenerator"],
	]]


func _put_up_for_sale(stack : ItemStack, inventory : Inventory, stash_index : int):
	stack.extra_properties[&"seller_stash_index"] = stash_index
	stack.extra_properties[&"for_sale"] = true
	if stash_index != -1 || !free_buyback:
		_apply_price_markup(stack)

	if stash_index != -1 && !infinite_restocks && stock_restocks[stash_index] > 0:
		stack.extra_properties[&"left_in_stock"] = stock_restocks[stash_index]


func _apply_price_markup(stack : ItemStack):
	if !stack.extra_properties.has(&"price"):
		return
	
	var price_dict = stack.extra_properties[&"price"]
	stack.extra_properties[&"real_price"] = price_dict.duplicate()
	for k in price_dict:
		price_dict[k] = int(price_dict[k] * price_markup)


func _multiply_price_by_count(stack : ItemStack, reverse : bool = false):
	var coeff = float(stack.count)
	if reverse:
		coeff = 1 / coeff

	var price_dict = stack.extra_properties[&"price"]
	for k in price_dict:
		price_dict[k] = int(price_dict[k] * coeff)


func _remove_from_sale(stack : ItemStack):
	var props = stack.extra_properties
	if props.has(&"price"):
		props[&"price"] = props.get(
			&"real_price", props[&"price"]
		)
		props.erase(&"real_price")

	if props[&"seller_stash_index"] == -1:
		_multiply_price_by_count(stack, true)

	props.erase(&"for_sale")
	props.erase(&"seller_stash_index")
	props.erase(&"left_in_stock")


func _on_Inventory_grab_attempted(item_stack : ItemStack, success : bool):
	var inventory = get_node(vendor_inventory).inventory
	if success:
		_restock_item(item_stack, inventory)
		_remove_from_sale(item_stack)
		if remove_price_on_buy:
			item_stack.extra_properties.erase(&"price")
		
		item_given.emit(item_stack)

	else:
		item_cant_afford.emit(item_stack)


func _restock_item(item_stack : ItemStack, inventory : Inventory):
	var stash_idx = item_stack.extra_properties[&"seller_stash_index"]
	if stash_idx == -1:
		return

	var left_in_stock = item_stack.extra_properties.get(&"left_in_stock", -1)
	var restock_item = get_stock(stash_idx)
	var restock_pos = item_stack.position_in_inventory

	# The item is not yet removed, only attempted to remove.
	# Wait until the restock can be placed 
	await get_tree().process_frame

	if !inventory.can_place_item(restock_item, restock_pos):
		restock_pos = inventory.get_free_position(restock_item)

	if infinite_restocks:
		_put_up_for_sale(restock_item, inventory, stash_idx)
		inventory.try_place_stackv(restock_item, restock_pos)

	elif left_in_stock > 1:
		_put_up_for_sale(restock_item, inventory, stash_idx)
		restock_item.extra_properties[&"left_in_stock"] = left_in_stock - 1
		inventory.try_place_stackv(restock_item, restock_pos)


func _on_Inventory_item_stack_added(item_stack : ItemStack):
	if item_stack.extra_properties.has(&"for_sale"):
		# Those are mine! Why would I give you money for MY items?!?!
		return
	
	item_received.emit(item_stack)
	if item_stack.extra_properties.has(&"price") && has_node(sell_reward_into_inventory):
		var inventory = get_node(sell_reward_into_inventory).inventory
		var reward = item_stack.extra_properties[&"price"]
		for k in reward:
			inventory.try_add_item(ItemStack.new(load(k) if k is String else k, reward[k] * item_stack.count))
	
	_put_up_for_sale(item_stack, get_node(vendor_inventory).inventory, -1)
	_multiply_price_by_count(item_stack, false)


func _on_visibility_changed():
	if !get_parent().is_visible_in_tree():
		if clear_sold_items_when_hidden:
			clear_sold_items()
