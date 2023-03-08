tool
class_name GroundItemStackView3D, "res://addons/wyvernbox/icons/item_stack_view_3d.png"
extends CollisionObject

signal clicked()

# The [ItemType] of the displayed item.
export(Resource) var item_type setget _set_item_type

# The count of the displayed item.
export var item_count := 1 setget _set_item_count

# The extra properties of the displayed item - if not set, uses type's [member ItemType.default_properties].
export var item_extra : Dictionary setget _set_item_extra

# Path to node that displays the item's [member ItemType.texture].
export var display_icon : NodePath

# Path to node that displays the item's [member ItemType.mesh], if it has one.
export var display_mesh : NodePath

# Paths to [SpriteBase3D] nodes that must change color to item's [code]"back_color"[/code] extra property.
export(Array, NodePath) var display_colorable

# The modulation to apply if filtered out by [member GroundItemManager.view_filter_patterns]. [code]Color(1, 1, 1, 1)[/code] to disable.
export var filter_hidden_color := Color(0.5, 0.5, 0.5, 0.5)


# The [member ItemStack.name_with_affixes] of the displayed item.
var item_affixes := [] setget _set_item_affixes

# [code]true[/code] if hidden by parent's [member GroundItemManager.view_filter_patterns].
var filter_hidden := false setget _set_filter_hidden

# The [ItemStack] displayed by this node.
var item_stack : ItemStack

var _jump_tween : SceneTreeTween


func _set_item_type(v):
	item_type = v
	_update_stack()


func _set_item_count(v):
	item_count = v
	_update_stack()


func _set_item_extra(v):
	item_extra = v
	_update_stack()


func _set_item_affixes(v):
	item_affixes = v
	_update_stack()


func _set_filter_hidden(v):
	filter_hidden = v
	# visible = !v
	get_node(display_icon).modulate = filter_hidden_color if v else Color.white


func set_label_visible(v):
	$"LabelView".visible = v

# Sets the displayed [ItemStack].
func set_stack(stack):
	item_type = stack.item_type
	item_count = stack.count
	item_extra = stack.extra_properties
	item_affixes = stack.name_with_affixes
	_update_stack()


func _ready():
	_update_stack()
	set_process_input(false)


func _update_stack():
	if item_type == null: return
	item_stack = ItemStack.new(item_type, item_count, item_extra)
	item_stack.name_with_affixes = item_affixes

	if !is_inside_tree(): yield(self, "ready")
	get_node(display_mesh).mesh = item_type.mesh
	item_stack.display_texture(get_node(display_icon))

	for x in display_colorable:
		get_node(x).modulate = item_extra.get("back_color", Color.gray)

	$"LabelVP/Label".item_stack = item_stack
	$"LabelVP".size = $"LabelVP/Label".get_bounding_rect().size
	$"LabelView".region_enabled = true
	$"LabelView".region_enabled = false

# Tries to add item into [code]into_inventory[/code], freeing this node on full success.
func try_pickup(into_inventory):
	var deposited_count = into_inventory.try_add_item(item_stack)
	item_count -= deposited_count
	if item_count <= 0:
		queue_free()


func skip_spawn_animation():
	pass

# Returns a random vector with length between [code]dist_min[/code] and [code]dist_max[/code].
func get_random_jump_vector(dist_min : float, dist_max : float) -> Vector3:
	return Vector3(
		rand_range(dist_min, dist_max),
		0,
		0
	).rotated(Vector3.UP, randf() * TAU)

# Plays jump animation and moves to global position [code]pos[/code].
# [code]upwards[/code] defines upwards velocity for 3D physics items, or arc height for non-physics items.
func jump_to_pos(pos, upwards = 9.8):
	if "linear_velocity" in self:
		self.linear_velocity = pos - global_translation + Vector3(0, upwards, 0)

	else:
		pos = get_world().direct_space_state.intersect_ray(pos, Vector3.DOWN * 999).get("position", pos)
		pos -= get_parent().global_translation

		_jump_tween = create_tween()
		_jump_tween.set_trans(Tween.TRANS_LINEAR).tween_property(
			self, "translation",
			lerp(translation, pos, 0.5), 0.25
		)
		_jump_tween.parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).tween_property(
			self, "translation:y",
			max(translation.y, pos.y) + upwards, 0.25
		)
		_jump_tween.set_trans(Tween.TRANS_LINEAR).tween_property(
			self, "translation",
			pos, 0.25
		)
		_jump_tween.parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).tween_property(
			self, "translation:y",
			pos.y, 0.25
		)

	$"Anim".play("init")
	$"Anim".seek(0)


func get_label_rect():
	return $"LabelVP/Label"


func _on_name_gui_input(event : InputEvent):
	if event is InputEventMouseButton && event.is_pressed() && event.button_index == BUTTON_LEFT:
		emit_signal("clicked")

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			emit_signal("clicked")

		# TODO: make this work with a tooltip
		# var tt = get_tree().get_nodes_in_group("tooltip")[0]
		# tt.display_item(item_stack, $"HoverRect", false)
		# if !Input.is_action_pressed("inventory_more"):
		# 	tt.hide()


func _on_mouse_exited():
	set_process_input(false)
	if !Input.is_action_pressed("inventory_less"):
		set_label_visible(false)
		get_tree().get_nodes_in_group("tooltip")[0]._on_ground_item_released()


func _on_mouse_entered():
	set_process_input(true)
	if !filter_hidden && !$"LabelView".visible:
		set_label_visible(true)
		# $"LabelView".position = Vector3(0, -2, 0)  # for label non-overlapping (TODO)
		if Input.is_mouse_button_pressed(BUTTON_LEFT):
			emit_signal("clicked")


func _input(event):
	if event is InputEventMouseButton && event.is_pressed() && event.button_index == BUTTON_LEFT:
		emit_signal("clicked")
