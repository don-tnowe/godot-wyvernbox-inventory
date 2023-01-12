class_name ItemPatternName
extends ItemPattern

export var name_to_search := ""


func _init(name_to_search, items := [], efficiency := []).(items, efficiency):
	self.name_to_search = name_to_search

# Returns `true` if `item_stack`s name contains `name_to_search`, case insensitive.
# Note: This pattern does NOT tokenize strings (that is, a "Wyvernite Shard" item will not be matched by query of "Wy Shar")
func matches(item_stack : ItemStack) -> bool:
	if !.matches(item_stack):
		return false

	return item_stack.get_name().findn(name_to_search) != -1
