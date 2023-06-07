class_name ItemPatternName
extends ItemPattern

## The string to search in the item's name, including affixes.
## Note: This pattern does NOT tokenize strings (that is, a "Wyvernite Shard" item will not be matched by query of "Wy Shar")
@export var name_to_search := ""


func _init(name_to_search, items := [], efficiency := []):
	super(items, efficiency)
	self.name_to_search = name_to_search

## Returns [code]true[/code] if [code]item_stack[/code]s full name contains [code]name_to_search[/code], case insensitive.
## Note: This pattern does NOT tokenize strings (that is, a "Wyvernite Shard" item will not be matched by query of "Wy Shar")
func matches(item_stack : ItemStack) -> bool:
	if name_to_search == "": return true
	if !super.matches(item_stack):
		return false

	return item_stack.get_name().findn(name_to_search) != -1
