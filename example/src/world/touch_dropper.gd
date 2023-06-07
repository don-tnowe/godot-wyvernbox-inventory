@tool
extends Node

@export var ground_item_manager : NodePath
@export var collide_with_group := &""
@export var loot_table : Resource


func _ready():
	var _1 = connect("body_entered", Callable(self, "_on_body_entered"))
	if loot_table == null:
		loot_table = ItemInstantiator.new()


func _on_body_entered(body):
	if collide_with_group == "" || body.is_in_group(collide_with_group):
		loot_table.populate_ground(self, get_node(ground_item_manager))
		queue_free()
