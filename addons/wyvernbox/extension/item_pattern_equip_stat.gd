class_name ItemPatternEquipStat
extends ItemPattern

# Items with this bonus in their "stats" extra property will match.
export(Array, String) var bonuses_required setget _set_bonuses_required
# Items which have each of [member bonuses_required] no less than [member bonuses_min], will match.
export(Array, float) var bonuses_min setget _set_bonuses_min
# Ignores stat amounts in [member bonuses_min] when matching.
export var ignore_min_requirement := true


func _init(items := [], efficiency := [], bonuses_required = [], bonuses_min = []).(items, efficiency):
	self.bonuses_required = bonuses_required
	self.bonuses_min = bonuses_min
	ignore_min_requirement = bonuses_min.size() == 0


func _set_bonuses_required(v):
	bonuses_required = v
	bonuses_required.resize(v.size())


func _set_bonuses_min(v):
	bonuses_min = v
	bonuses_min.resize(v.size())

# Returns [code]true[/code] if [code]item_stack[/code]'s stats fulfill the requirements.
func matches(item_stack : ItemStack) -> bool:
	if !.matches(item_stack):
		return false

	if !item_stack.extra_properties.has("stats"):
		return false

	var bonuses = item_stack.extra_properties["stats"]
	if ignore_min_requirement:  # then just check types
		for i in bonuses_required.size():
			if !bonuses.has(bonuses_required[i]):
				return false

	else:
		for i in bonuses_required.size():
			if bonuses.get(bonuses_required[i], 0.0) < bonuses_min[i]:
				return false

	return true

# Returns [code]0[/code] if [code]item_stack[/code]'s stats do not fulfill the requirements - otherwise, see [method ItemPattern.get_value].
func get_value(of_stack : ItemStack) -> float:
	if matches(of_stack): return .get_value(of_stack)
	else: return 0.0
