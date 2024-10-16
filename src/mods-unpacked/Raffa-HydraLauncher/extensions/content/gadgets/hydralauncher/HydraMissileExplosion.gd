extends Node2D

var taser := false

func _ready():
	Style.init(self)
	$BulletImpact.frame = 0
	$BulletImpact.play("Impact")
	$Particles.emitting = true
	$ExplosionSmall.frame = 0
	$ExplosionSmall.play("Small")
	if taser:
		$StunParticle.restart()

func _on_BulletImpact_animation_finished():
	$BulletImpact.hide()
