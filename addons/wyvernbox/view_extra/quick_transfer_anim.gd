class_name QuickTransferAnimation
extends Control

## Animates the Quick Transfer (default: Shift + Left-Click) user action for inventory views.
##
## This node has global effect, [b]but[/b] will not animate inventories added after this node - register them via [method register_inventory]. [br]
## This node also does not respect the [code]"custom_texture"[/code] and [/code]"texture_colors"[/code] [member ItemType.extra_properties], only drawing the default texture of the item type.

class QuickTransferAnimInstance extends RefCounted:
	var global_xform_start := Transform2D()
	var global_xform_end := Transform2D()
	var size_start := Vector2()
	var size_end := Vector2()
	var item_stack : ItemStack
	var item_stack_tex_half_size : Vector2
	var progress := 0.0
	var finished := false


@export var duration := 0.5
@export var easing := 0.5
@export var anim_ghost_count := 5
@export var anim_ghost_spacing_sec := 0.1
@export var anim_ghost_color := Color.WHITE
@export var anim_destination_color := Color.WHITE
@export var anim_item_color := Color.WHITE

var _ongoing_anims : Array[QuickTransferAnimInstance] = []
var _ongoing_anims_active := 0

var _current_qt_listening := false
var _current_qt_from_inventory : InventoryView
var _current_qt_stack_transfered : ItemStack
var _current_qt_xform_start := Transform2D()
var _current_qt_size_start := Vector2()

static var _instance : QuickTransferAnimation


func _enter_tree():
	assert(!is_instance_valid(_instance), "Multiple GrabbedItemStack instances detected in the scene - perhaps you added one to an instantiated scene?. Only one GrabbedItemStack can exist in the game scene.")
	_instance = self

## Registers an inventory. Actions with that inventory will play an animation.
func register_inventory(x : InventoryView):
	x.before_quick_transfer.connect(_on_quick_transfer.bind(x))
	x.item_stack_added.connect(_on_item_stack_added.bind(x))
	x.item_stack_changed.connect(_on_item_stack_changed.bind(x))
	x.grab_attempted.connect(_on_grab.bind(x))


static func get_instance() -> QuickTransferAnimation:
	return _instance


func _ready() -> void:
	set_process(false)
	for x in InventoryView.get_instances():
		register_inventory(x)


func _process(delta: float) -> void:
	delta /= duration
	for x in _ongoing_anims:
		x.progress += delta
		if !x.finished && x.progress > 1.0:
			x.finished = true
			_ongoing_anims_active -= 1
			if _ongoing_anims_active == 0:
				set_process(false)
				_ongoing_anims.clear()
				break

			continue

	queue_redraw()


func _draw() -> void:
	if _ongoing_anims_active <= 0:
		return

	for x in _ongoing_anims:
		if x.finished: continue
		var item_tex_xform := Transform2D.IDENTITY
		for i in anim_ghost_count:
			var current_progress := clampf((x.progress + anim_ghost_spacing_sec * i), 0.0, 1.0)
			# This option distributes ghosts evenly-ish so that the line between stack 1 and stack 2 is visible.
			# var current_progress := clampf((x.progress + anim_ghost_spacing_sec * i) * (i + 1), 0.0, 1.0)
			current_progress = ease(current_progress, easing)
			draw_set_transform_matrix(x.global_xform_start.interpolate_with(x.global_xform_end, current_progress))
			draw_rect(Rect2(Vector2.ZERO, x.size_start.lerp(x.size_end, current_progress)), Color(anim_ghost_color, anim_ghost_color.a * (1.0 - current_progress)))
			if i == anim_ghost_count - 1:
				item_tex_xform = x.global_xform_start.interpolate_with(x.global_xform_end, current_progress)

		draw_set_transform_matrix(x.global_xform_end)
		draw_rect(Rect2(Vector2.ZERO, x.size_end), Color(anim_destination_color, anim_destination_color.a * (1.0 - x.progress)))
		draw_set_transform_matrix(
			item_tex_xform
			.scaled_local(x.item_stack.item_type.texture_scale * Vector2.ONE)
			.translated(x.item_stack_tex_half_size + x.size_end * 0.5)
		)
		draw_texture(x.item_stack.item_type.texture, Vector2.ZERO, anim_item_color)


func _on_quick_transfer(potential_targets : Array[InventoryView], stack_transfered : ItemStack, stack_view_local_rect : Rect2, inventory_view : InventoryView):
	_current_qt_from_inventory = inventory_view
	_current_qt_stack_transfered = stack_transfered
	_current_qt_xform_start = inventory_view.get_global_transform().translated_local(stack_view_local_rect.position)
	_current_qt_size_start = stack_view_local_rect.size
	_current_qt_listening = true


func _on_grab(item_stack : ItemStack, success : bool, inventory_view : InventoryView):
	if !success:
		return

	_current_qt_listening = false
	set_process(true)


func _on_item_stack_added(stack : ItemStack, inventory_view : InventoryView):
	_on_item_stack_changed(stack, stack.count, inventory_view)


func _on_item_stack_changed(stack : ItemStack, count_delta : int, inventory_view : InventoryView):
	if !_current_qt_listening || count_delta == 0:
		return

	if _current_qt_from_inventory.inventory == inventory_view.inventory:
		return

	_ongoing_anims_active += 1
	var new_anim := QuickTransferAnimInstance.new()
	_ongoing_anims.append(new_anim)
	new_anim.global_xform_start = _current_qt_xform_start
	new_anim.size_start = _current_qt_size_start

	var item_rect := inventory_view.get_selected_rect(stack.position_in_inventory)
	new_anim.global_xform_end = inventory_view.get_global_transform().translated_local(item_rect.position)
	new_anim.size_end = item_rect.size
	new_anim.progress = -anim_ghost_spacing_sec * anim_ghost_count
	new_anim.item_stack = stack
	new_anim.item_stack_tex_half_size = -stack.item_type.texture.get_size() * stack.item_type.texture_scale * 0.5
