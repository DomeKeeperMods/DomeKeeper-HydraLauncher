extends Node2D

func _ready():
	Style.init($Sprite)
	var newScale = Vector2(randf_range(1.1, 1.4), randf_range(1.1, 1.4)) * scale.x
	var t := create_tween()
	t.tween_property(self, "scale", newScale, 0.03).from(Vector2.ZERO).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.tween_property(self, "scale", newScale*0.5, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	t.tween_callback(queue_free)
