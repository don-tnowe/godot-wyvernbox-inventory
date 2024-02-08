@tool
class_name ItemGeneratorEquipmentBonus
extends ItemGenerator

## An [ItemGenerator] that outputs an item with a random stat bonus, drawing from a list of [EquipBonus].

## The [EquipBonus] objects that may be applied to the item.
@export var possible_affixes : Array[EquipBonus]

## The non-normalized chances for each [EquipBonus] to be applied.
@export var affix_weights : Array[float]

## Generates between [code]x[/code] and [code]y[/code] affixes.
@export var affix_count_range := Vector2(1, 1)

## Generates affixes of levels between [code]x[/code] and [code]y[/code]. See [EquipBonus.get_value].
@export var affix_level_range := Vector2(1, 6)

## If [code]true[/code], don't append the affix to the name if there is already an affix at that position.
@export var only_one_affix := true

## Item's "price" extra property will grow. It will cost more of this item.
@export var price_increase_item : ItemType

## Item's "price" extra property will grow by this, multiplied by sum of affix levels added.
@export var price_increase_per_level := 20


## Returns a random [member results] item with a random affix from [member possible_affixes]. [br]
## If no [member results] set, adds affix to the first item that matches the first item defined as [ItemConversion] input.
func get_items(rng : RandomNumberGenerator = null, input_stacks : Array = [], input_types : Array = []):
	var items := super.get_items(rng, input_stacks, input_types)
	var operate_on_item : ItemStack

	# Choose which item gets the affixes/enchantments/modifiers/whatever.
	if items.size() == 0 || items[0] == null:
		# If called from an [ItemConversion], must modify the consumed equipment item.
		# For that, it must be found in [input_stacks] - it should match a pattern or type specified in [input_types].
		for x in input_stacks:
			if input_types[0].matches(x):
				operate_on_item = x
				items.append(x)
				break

	else:
		# If not, get the superclass's output ([ItemGenerator], gives random item from a list).
		operate_on_item = items[0]

	# The rest of the stuff. Create an RNG if not provided, call the func that modifies the chosen item.
	if rng == null:
		rng = RandomNumberGenerator.new()

	for i in rng.randi_range(affix_count_range.x, affix_count_range.y):
		add_affix(operate_on_item, rng)

	return items

## Adds a random affix to [code]item[/code].
func add_affix(item : ItemStack, rng : RandomNumberGenerator):
	var extras := item.extra_properties
	var random_affix := possible_affixes[weighted_random(affix_weights, rng)]
	var random_level := int(rng.randf_range(affix_level_range.x, affix_level_range.y))

	if !extras.has(&"stat_affixes"):
		extras[&"stat_affixes"] = {}

	if !extras.has(&"stats"):
		extras[&"stats"] = {}

	if !extras.has(&"price"):
		extras[&"price"] = {}

	# Remember: don't store objects in item properties, use paths instead.
	extras[&"stat_affixes"][random_affix.resource_path] = random_level
	var price : Dictionary = extras[&"price"]
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

## Must return settings for displays of item lists. Override to change behaviour, or add to your own class.
## See [method ItemGenerator._get_wyvernbox_item_lists].
func _get_wyvernbox_item_lists() -> Array:
	var result = super._get_wyvernbox_item_lists()
	result.append([
		"Bonuses", ["possible_affixes", "affix_weights"],
		["Weight"], [false], [1],
		[EquipBonus], ["EquipBonus"],
	])
	return result
