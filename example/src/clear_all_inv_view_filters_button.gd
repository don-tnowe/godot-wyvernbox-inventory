extends Button


func _pressed():
  for x in get_tree().get_nodes_in_group("inventory_view"):
    x.clear_view_filters()


func _on_search_text_changed(new_text : String):
  var filters = []
  if new_text != "":
    filters = [ItemPatternName.new(new_text)]

  for x in get_tree().get_nodes_in_group("inventory_view"):
    x.view_filter_patterns = filters
