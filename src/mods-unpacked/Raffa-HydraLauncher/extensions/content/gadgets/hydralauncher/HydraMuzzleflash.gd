extends Node2D

func _ready():
	Style.init($Sprite)
	var newScale = Vector2(rand_range(1.1, 1.4), rand_range(1.1, 1.4)) * scale.x
	$Tween.interpolate_property(self, "scale", Vector2.ZERO, newScale, 0.03, Tween.TRANS_EXPO, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "scale", newScale, Vector2.ZERO, 0.35, Tween.TRANS_QUINT, Tween.EASE_OUT, 0.03)
	$Tween.interpolate_callback(self, 0.08, "queue_free")
	$Tween.start()
