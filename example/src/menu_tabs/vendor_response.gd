extends Label


func _ready():
	call_deferred("say", "shopkeeper_hello", Color.green)


func say(say_text, color = Color(1.0, 0.9, 0.1, 1.0)):
	text = say_text
	modulate = color

	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.white, 1)


func _on_ShopManager_item_received(_stack):
	say("shopkeeper_sold", Color.green)


func _on_ShopManager_item_given(_stack):
	say("shopkeeper_purchase", Color.darkturquoise)


func _on_ShopManager_item_cant_afford(_stack):
	say("shopkeeper_cant_afford", Color.red)
