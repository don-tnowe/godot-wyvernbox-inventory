tool
class_name ItemGenerator, "res://addons/wyvernbox/icons/item_generator.png"
extends Resource

export var name := "Insert name or full locale string"
export var texture : Texture
export(Array, Resource) var results setget _set_results
export(Array, float) var weights setget _set_weights
export(Array, Vector2) var count_ranges setget _set_count_ranges


func _set_results(v):
	results = v
	_resize_arrays(v.size())


func _set_weights(v):
	weights = v
	_resize_arrays(v.size())


func _set_count_ranges(v):
	count_ranges = v
	_resize_arrays(v.size())


func _resize_arrays(size):
	size = max(size, 1)
	results.resize(size)
	weights.resize(size)
	count_ranges.resize(size)
	for i in size:
		if weights[i] == null || weights[i] == 0.0:
			weights[i] = 1.0

		if count_ranges[i] == null || count_ranges[i] == Vector2.ZERO:
			count_ranges[i] = Vector2.ONE

# Get a random `results` with random `count_ranges`, considering their random `weights`.
# Override to define special item generators that modify results or `input_stacks`.
func get_items(rng : RandomNumberGenerator = null, input_stacks : Array = [], input_types : Array = []) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	if results[0] == null:
		assert(input_stacks.size() > 0, "Generator with blank Result received no Inputs!\n\nPerhaps you called consume_inputs() without passing its return value to get_items()?")
		assert(input_types.size() > 0, "Generator with blank Result received no Input Types!\n\nSome Generators need a list of input types to get the First to modify it.")

	var item_index = weighted_random(weights, rng) if results.size() > 0 else 0
	var item = results[item_index]
	if item == null:
		return []

	if item is ItemType:
		return [ItemStack.new(
			item,
			int(rng.randf_range(count_ranges[item_index].x, count_ranges[item_index].y)),
			item.default_properties.duplicate(true)
		)]

	elif item is get_script():  # If nested ItemGenerator
		return item.get_items(rng, input_stacks, input_types)

	return []

# Returns a random number. Non-normalized chances are defined inside `weights`.
# If `rng` not set, uses global RNG.
static func weighted_random(weights : Array, rng : RandomNumberGenerator = null) -> int:
	var sum = 0.0
	for i in weights.size():
		sum += weights[i]

	var val = 0.0
	if rng == null:
		val = randf() * sum
	
	else:
		val = rng.randf() * sum

	for i in weights.size():
		if val < weights[i]:
			return i

		val -= weights[i]

	return -1
