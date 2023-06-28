extends Sprite


func _process(delta):
	var oscillate : float = sin(wrapf(OS.get_ticks_msec()*0.03, 0, TAU))
	modulate.a = 0.8 + oscillate * 0.2
