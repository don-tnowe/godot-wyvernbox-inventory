tool
extends EditorProperty

var hint_node : Control


func _ready():
	hint_node = load("res://addons/wyvernbox/editor/inspector_inventory_creator.tscn").instance()

	var style = StyleBoxFlat.new()
	style.bg_color = get_color("accent_color", "Editor")
	style.bg_color.a = 0.25
	hint_node.add_stylebox_override("panel", style)

	if get_parent() == null: return
	get_parent().add_child(hint_node)
	get_parent().move_child(hint_node, get_position_in_parent())

	hint_node.get_node("Box/Box/Box/Button").icon = get_icon("Add", "EditorIcons")
	hint_node.get_node("Box/Box/Box/Button2").icon = get_icon("Add", "EditorIcons")
	hint_node.get_node("Box/Box/Box/Button3").icon = get_icon("Add", "EditorIcons")
	hint_node.get_node("Box/Box/Box/Button4").icon = get_icon("Add", "EditorIcons")

	hint_node.get_node("Box/Box/Box/Button").connect("pressed", self, "_on_create_pressed", [Inventory, "Inventory"])
	hint_node.get_node("Box/Box/Box/Button2").connect("pressed", self, "_on_create_pressed", [GridInventory, "GridInventory"])
	hint_node.get_node("Box/Box/Box/Button3").connect("pressed", self, "_on_create_pressed", [RestrictedInventory, "RestrictedInventory"])
	hint_node.get_node("Box/Box/Box/Button4").connect("pressed", self, "_on_create_pressed", [CurrencyInventory, "CurrencyInventory"])

	label = "---"
	hide()
	_update_property()


func _on_create_pressed(inv_class, inv_name):
	var new_inv = inv_class.new()
	new_inv.resource_name = inv_name
	emit_changed(get_edited_property(), new_inv, "", false)
	_update_property()


func _update_property():
	hint_node.visible = get_edited_object()[get_edited_property()] == null
