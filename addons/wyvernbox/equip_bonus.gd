class_name EquipBonus
extends Resource

# The bonus's ID, stored in item's [member ItemStack.extra_properties] at "stats".
@export var id := &"health"

# The bonus's name. Can be a locale string.
@export var name := &"health"

# The bonus's description. Can be a locale string, or empty.
@export_multiline var description := "health"

# The affix appended or prepended to the name. Can be a locale string.
@export var affix := ""

# The position of the affix: [code]-1[/code] if placed before name, [code]1[/code] if after.
@export var affix_position := -1

# The icon of this bonus.
@export var texture : Texture2D

# The background texture of the icon.
@export var texture_back : Texture2D

# The maximum level of the bonus.
@export var max_level := 10


# The value of the bonus at level 0. See [method get_value].
@export var bonus_init := 10.0

# The linear growth of the value per level. See [method get_value].
@export var bonus_linear := 5.0

# The quadratic growth of the value per level. See [method get_value].
@export var bonus_quad := 0.2

# Must be [code]true[/code] if a percentage sign must be appended in stat lists.
@export var is_percentage := false

# Must be [code]true[/code] if the result of [method get_value] must be integer.
@export var integer_only := true


# Returns the stat bonus at the specified affix level.
# Equation: [code]bonus_init + bonus_linear * level + bonus_quad * level * level[/code]
func get_value(level : int = 1) -> float:
	if !integer_only:
		return bonus_init + bonus_linear * level + bonus_quad * level * level

	else:
		return floor(bonus_init + bonus_linear * level + bonus_quad * level * level)

# Adds the stats bonus of the specified level to the dictionary.
# See [method get_value].
func apply_to(stats_dict : Dictionary, level : int, multiplier : float = 1.0):
	stats_dict[id] = stats_dict.get(id, 0.0) + get_value(level) * multiplier

# Add the affix to an item's name array. If [code]only_if_empty[/code], only append if there's no affix at the same position.
func append_affix(item : ItemStack, only_if_empty : bool = false):
	if only_if_empty || affix_position == 0:
		item.set_name(affix, affix_position)
		return

	if affix_position < 0:
		item.set_name(affix, -(item.name_prefixes.size() + 1))

	else:
		item.set_name(affix, item.name_suffixes.size() + 1)