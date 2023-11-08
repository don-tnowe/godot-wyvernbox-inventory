@tool
class_name ItemGeneratorEquipmentBonus
extends ItemGenerator

## The [EquipBonus] objects that may be applied to the item.
@export var possible_affixes : Array[EquipBonus]

## The non-normalized chances for each [EquipBonus] to be applied.
@export var affix_weights : Array[float]

## Generates between [code]x[/code] and [code]y[/code] affixes.
@export var affix_count_range := Vector2(1, 1)

## Generates affixes of levels between [code]x[/code] and [code]y[/code]. See [EquipBonus.get_value].
@export var affix_level_range := Vector2(1, 6)

# If [code]true[/code], don't append the affix to the name if there is already an affix at that position.
@export var only_one_affix := true

# Item's "price" extra property will grow. It will cost more of this item.
@export var price_increase_item : ItemType

# Item's "price" extra property will grow by this, multiplied by sum of levels added.
@export var price_increase_per_level := 20


# Returns a random [member results] item with a random affix from [member possible_affixes].
# If no [member results] set, adds affix to the first of [code]input_types[/code].
func get_items(rng = null, input_stacks = [], input_types = []):
	var items = super.get_items(rng, input_stacks, input_types)
	if items.size() == 0:
		items.resize(1)

	if items[0] == null:
		for x in input_stacks:
			if input_types[0].matches(x):
				items[0] = x
				break

	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	for i in int(rng.randf_range(affix_count_range.x, affix_count_range.y)):
		add_affix(items[0], rng)

	return items

# Adds a random affix to [code]item[/code].
func add_affix(item, rng : RandomNumberGenerator):
	var extras = item.extra_properties
	var random_affix = possible_affixes[weighted_random(affix_weights, rng)]
	var random_level = int(rng.randf_range(affix_level_range.x, affix_level_range.y))

	if !extras.has(&"stat_affixes"):
		extras[&"stat_affixes"] = {}

	if !extras.has(&"stats"):
		extras[&"stats"] = {}

	if !extras.has(&"price"):
		extras[&"price"] = {}

	# Remember: don't store objects in item properties.
	extras[&"stat_affixes"][random_affix.resource_path] = random_level
	var price = extras[&"price"]
	if price.has(price_increase_item.resource_path):
		price[price_increase_item.resource_path] += random_level * price_increase_per_level

	# UPDATE: you can store them like that now, if it's a resource from project. Which item types are expected to be. yaaaay
	elif price.has(price_increase_item):
		price[price_increase_item] += random_level * price_increase_per_level

	# But better stay safe here.
	else:
		price[price_increase_item.resource_path] = random_level * price_increase_per_level

	random_affix.apply_to(extras[&"stats"], random_level, 1.0)
	random_affix.append_affix(item, only_one_affix)

# Must return settings for displays of item lists. Override to change behaviour, or add to your own class.
# See [method ItemGenerator._get_wyvernbox_item_lists].
func _get_wyvernbox_item_lists() -> Array:
	var result = super._get_wyvernbox_item_lists()
	result.append([
		"Bonuses", ["possible_affixes", "affix_weights"],
		["Weight"], [false], [1],
		[EquipBonus], ["EquipBonus"],
	])
	return result
