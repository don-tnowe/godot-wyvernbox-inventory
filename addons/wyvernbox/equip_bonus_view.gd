extends Control

# The [EquipBonus] displayed here. Defines icon and tooltip contents.
@export var shown_res : EquipBonus


# Sets the displayed [EquipBonus] with [code]label[/code] of [code]label_color[/code].
# Optionally, pass a background texture. If not set, uses the bonus's default background.
func show_bonus(bonus_res : EquipBonus, label : String, label_color : Color = Color.WHITE, background : Texture2D = null):
  shown_res = bonus_res
  show()
  $"Back".texture = bonus_res.texture_back if background == null else background
  $"Icon".texture = bonus_res.texture
  $"Value".text = label
  $"Value".self_modulate = label_color


func _on_Bonus_mouse_exited():
  get_tree().get_nodes_in_group(&"tooltip")[0].hide()


func _on_Bonus_mouse_entered():
  var tt = get_tree().get_nodes_in_group(&"tooltip")[0]
  tt.display_bonus(self, shown_res)
