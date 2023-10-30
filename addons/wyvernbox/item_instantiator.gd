@icon("res://addons/wyvernbox/icons/item_instantiator.png")
class_name ItemInstantiator
extends Resource

## A list of items with random chances and amounts.
##
## Can be used to initialize inventories or describe loot drop tables.

## The [ItemType]s or [ItemGenerator]s to instantiate.
@export var items_to_add : Array[ItemLike]

## The minimum and maximum repeat counts of each item instantiated.
@export var item_repeat_ranges : Array[Vector2]

## The percentage chances for each item to be instantiated. 100 is "Always", 0 is "Never". [br]
## If you need only one of the items to spawn with different chances, add an [ItemGenerator] instead.
@export var item_chances : Array[float]

## Optionally, a generator to modify all instantiated items.
@export var apply_to_all_results : ItemGenerator

## Defines order of [member item_repeat_ranges] and [member item_chances]. [br]
## If [code]true[/code], spawns [code]x-y[/code] items if spawn succeeds, and none otherwise. [br]
## If [code]false[/code], checks chance [code]x-y[/code] times and spawn once for every success.
@export var repeat_post_chance := true

## If [code]true[/code], spawn items at random positions. [br]
## If [code]false[/code], an [InventoryView] will receive items in first available slots with stacking,
## and a [GroundItemManager] will spawn items in a circle or arc.
@export var randomize_locations := true

## Delay between item spawns when a [code]populate_*[/code] method is called.
@export_range(0, 60.0) var delay_between_items := 0.0

@export_group("Ground")

## For ground drops, sets the max distance the items get spread on the ground.
@export var spread_distance := 32.0

## For ground drops, sets the angle range the items get thrown in.
@export_range(0, 360.0) var spread_cone_degrees := 360.0

## For cone-shaped ground drops, sets the median angle the items get thrown in.
@export_range(0, 360.0) var spread_angle_degrees := 0.0

## The [RandomNumberGenerator] this object uses to randomize drops.
var rng : RandomNumberGenerator = null


func get_rng(passed_rng : RandomNumberGenerator):
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	return rng if passed_rng == null else passed_rng


## Adds listed items to an [InventoryView] or [Inventory]. [br]
## [b]Note:[/b] timed insertions only work if used on an [InventoryView].
func populate_inventory(target_inventory : Object, rng : RandomNumberGenerator = null):
	rng = get_rng(rng)
	var inventory : Inventory = target_inventory.inventory if target_inventory is InventoryView else target_inventory
	var generated_items = get_items(rng)
	if !randomize_locations:
		for x in generated_items:
			inventory.try_add_item(x)
			if delay_between_items > 0.0 && target_inventory is Node:
				await target_inventory.get_tree().create_timer(delay_between_items).timeout

	else:
		## TODO: optimize this heckin' chonker
		## Takes ~69 ms for 64 stacks, which is HUGE - think of the loading times
		##     if there are many inventories in the level generated at start

		## Both loops on generated_items take similar times.

		## var start_time = OS.get_ticks_usec()
		var free_cells := {}
		var is_grid := inventory is GridInventory

		## Get possible positions for all item sizes present
		var cur_size : Vector2
		var cur_free_cells : Array
		for x in generated_items:
			cur_size = x.item_type.get_size_in_inventory()
			free_cells[Vector2.ONE] = inventory.get_all_free_positions()

			if !free_cells.has(cur_size):
				free_cells[cur_size] = {}
				if is_grid:
					free_cells[cur_size] = inventory.get_all_free_positions(cur_size.x, cur_size.y)

				else:
					free_cells[cur_size] = free_cells[Vector2.ONE]

		## Actually place the items. Clear cells that matching sizes won't be able to be placed in
		var place_in_cell : Vector2
		for x in generated_items:
			cur_size = x.item_type.get_size_in_inventory()
			cur_free_cells = free_cells[cur_size]
			if cur_free_cells.size() == 0:
				continue

			place_in_cell = cur_free_cells[randi() % cur_free_cells.size()]
			if inventory is GridInventory:
				for k in free_cells:
					for i in cur_size.x + k.x - 1:
						for j in cur_size.y + k.y - 1:
							free_cells[k].erase(place_in_cell - k + Vector2.ONE + Vector2(i, j))

			else:
				for k in free_cells:
					free_cells[k].erase(place_in_cell)

			inventory.try_place_stackv(x, place_in_cell)
			if delay_between_items > 0.0 && target_inventory is Node:
				await target_inventory.get_tree().create_timer(delay_between_items).timeout

		## print(start_time - OS.get_ticks_usec())

	return generated_items

## Drops listed items to the ground.
func populate_ground(origin : Node, ground : GroundItemManager, rng : RandomNumberGenerator = null):
	rng = get_rng(rng)
	var tree = ground.get_tree()
	var generated_items := get_items(rng)
	var is_3d := !origin is Node2D
	var spawn_origin = origin.global_position if is_3d else origin.global_position

	await tree.process_frame  # Ground items tend to have phys objects and be created when something's destroyed

	var spread_rad := deg_to_rad(spread_cone_degrees) * 0.5
	var dir_rad := deg_to_rad(spread_angle_degrees)
	var dist_range := ground.spawn_jump_length_range / ground.spawn_jump_length_range.y * spread_distance
	var cur_throw

	if randomize_locations:
		for x in generated_items:
			if is_3d:
				cur_throw = Basis(Vector3.UP, randf_range(dir_rad - spread_rad, dir_rad + spread_rad))
				cur_throw = cur_throw.scaled(Vector3.ONE * randf_range(dist_range.x, dist_range.y))

			else:
				cur_throw = Transform2D(randf_range(dir_rad - spread_rad, dir_rad + spread_rad), Vector2.ZERO)
				cur_throw = cur_throw.scaled(Vector2.ONE * randf_range(dist_range.x, dist_range.y))

			ground.add_item(x, spawn_origin, cur_throw * (Vector3.RIGHT if is_3d else Vector2.RIGHT))
			if delay_between_items > 0.0:
				await tree.create_timer(delay_between_items).timeout

	else:
		var rotate_by
		if is_3d:
			rotate_by = Basis(Vector3.UP, spread_rad * 2.0 / generated_items.size())
			cur_throw = Basis(Vector3.UP, dir_rad - spread_rad)
			cur_throw = cur_throw.scaled(Vector3(spread_distance, spread_distance, spread_distance))

		else:
			rotate_by = Transform2D(spread_rad * 2.0 / generated_items.size(), Vector2.ZERO)
			cur_throw = Transform2D(dir_rad - spread_rad, Vector2.ZERO)
			cur_throw = cur_throw.scaled(Vector2(spread_distance, spread_distance))

		for x in generated_items:
			ground.add_item(x, spawn_origin, cur_throw * (Vector3.RIGHT if is_3d else Vector2.RIGHT))
			cur_throw = rotate_by * cur_throw
			if delay_between_items > 0.0:
				await tree.create_timer(delay_between_items).timeout

	return generated_items

## Returns a list filled with [member items_to_add] with [member item_chances] percent chances repeated [member item_repeat_ranges] times. [br]
## Used internally, but you can use this manually to define custom spawning behaviour.
func get_items(rng : RandomNumberGenerator = null) -> Array:
	if rng == null: rng = self.rng

	var generated_items := []
	for i in items_to_add.size():
		var item = items_to_add[i]
		var repeats := rng.randi_range(item_repeat_ranges[i].x, item_repeat_ranges[i].y)

		for i_pre in repeats if !repeat_post_chance else 1:
			if rng.randf() > item_chances[i] * 0.01: continue
			if item is ItemGenerator:
				for i_post in repeats if repeat_post_chance else 1:
					generated_items.append_array(item.get_items(rng))

			else:
				generated_items.append(ItemStack.new(item, repeats if repeat_post_chance else 1, item.default_properties))

	if apply_to_all_results == null:
		return generated_items

	var actual_generated_items := []
	for x in generated_items:
		actual_generated_items.append_array(apply_to_all_results.get_items(rng, [x], [x.item_type]))

	return actual_generated_items


## Must return settings for displays of item lists. Override to change behaviour, or add to your own class. [br]
## The returned arrays must contain: [br]
## - Property editor label : String [br]
## - Array properties edited : Array[String] (the resource array must be first; the folowing props skip the resource array) [br]
## - Column labels : Array[String] (each vector array must have two/three) [br]
## - Columns are integer? : bool (each vector array maps to one) [br]
## - Column default values : Variant [br]
# - Allowed resource types : Array[Script or Classname]
func _get_wyvernbox_item_lists() -> Array:
	return [[
		"Items To Add", ["items_to_add", "item_repeat_ranges", "item_chances"],
		["Min", "Max", "Chance"], [true, false], [Vector2(1, 1), 100.0],
		[ItemType, ItemGenerator], ["ItemType", "ItemGenerator"],
	]]
