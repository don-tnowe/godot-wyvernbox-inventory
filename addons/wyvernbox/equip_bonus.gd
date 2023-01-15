class_name EquipBonus
extends Resource

# The bonus's ID, stored in item's `extra_properties["stats"]`.
export var id := "health"
# The bonus's name. Can be a locale string.
export var name := "health"
# The bonus's description. Can be a locale string, or empty.
export(String, MULTILINE) var description := "health"
# The affix appended or prepended to the name. Can be a locale string.
export var affix := ""
# The position of the affix: `-1` if placed before name, `1` if after.
export var affix_position := -1
# The icon of this bonus.
export var texture : Texture
# The background texture of the icon.
export var texture_back : Texture

# The maximum level of the bonus.
export var max_level := 10
# The value of the bonus at level 0. See `get_value`.
export var bonus_init := 10.0
# The linear growth of the value per level. See `get_value`.
export var bonus_linear := 5.0
# The quadratic growth of the value per level. See `get_value`.
export var bonus_quad := 0.2

# Must be `true` if a percentage sign must be appended in stat lists.
export var is_percentage := false
# Must be `true` if the result of `get_value` must be integer.
export var integer_only := true

# Returns the stat bonus at the specified affix level.
# Equation: `bonus_init + bonus_linear * level + bonus_quad * level * level`
func get_value(level : int = 1) -> float:
	if !integer_only:
		return bonus_init + bonus_linear * level + bonus_quad * level * level

	else:
		return floor(bonus_init + bonus_linear * level + bonus_quad * level * level)

# Adds the stats bonus of the specified level to the dictionary.
# See `get_value`.
func apply_to(stats_dict : Dictionary, level : int, multiplier : float = 1.0):
	stats_dict[id] = stats_dict.get(id, 0.0) + get_value(level) * multiplier

# Add the affix to an item's name array.
func append_affix(affixes_array : Array):
	if affix_position < 0:
		affixes_array.insert(0, affix)

	else:
		affixes_array.append(affix)
