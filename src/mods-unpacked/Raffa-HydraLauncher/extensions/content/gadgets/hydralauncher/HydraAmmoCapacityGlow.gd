extends Sprite2D


func _process(delta):
	var oscillate : float = sin(wrapf(Time.get_ticks_msec()*0.03, 0, TAU))
	modulate.a = 0.8 + oscillate * 0.2
