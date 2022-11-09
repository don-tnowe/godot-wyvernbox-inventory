tool
class_name ItemGenerator
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
	results.resize(size)
	weights.resize(size)
	count_ranges.resize(size)
	for i in size:
		if weights[i] == 0.0:
			weights[i] = 1.0

		if count_ranges[i] == Vector2.ZERO:
			count_ranges[i] = Vector2.ONE


func get_item(rng : RandomNumberGenerator = null) -> ItemStack:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	var item_index = weighted_random(weights, rng)
	return ItemStack.new(
		results[item_index],
		int(rng.randf_range(count_ranges[item_index].x, count_ranges[item_index].y)),
		results[item_index].default_properties.duplicate(true)
	)


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
