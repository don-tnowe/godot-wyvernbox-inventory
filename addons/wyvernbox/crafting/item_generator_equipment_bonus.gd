tool
class_name ItemGeneratorEquipmentBonus
extends ItemGenerator

export(Array, Resource) var possible_affixes
export var affix_count_range := Vector2(1, 1)
export var affix_level_range := Vector2(1, 6)


func get_item(rng = null):
	var item = .get_item(rng)
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()

	for i in int(rng.randf_range(affix_count_range.x, affix_count_range.y)):
		add_affix(item, rng)

	return item


func add_affix(item, rng):
	var extras = item.extra_properties
	var random_affix = possible_affixes[rng.randi() % possible_affixes.size()]
	var random_level = int(rng.randf_range(affix_level_range.x, affix_level_range.y))

	if !extras.has("stat_affixes"):
		extras["stat_affixes"] = {}

	if !extras.has("stats"):
		extras["stats"] = {}
	
	# Remember: don't store objects in item properties. Will be easier to serialize.
	extras["stat_affixes"][random_affix.resource_path] = random_level
	random_affix.apply_to(extras["stats"], random_level, 1.0)
	random_affix.append_affix(item.name_with_affixes)
