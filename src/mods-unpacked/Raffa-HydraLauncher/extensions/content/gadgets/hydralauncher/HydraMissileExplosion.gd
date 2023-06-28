extends Node2D

var taser := false

func _ready():
	Style.init(self)
	$BulletImpact.frame = 0
	$Particles.emitting = true
	$ExplosionSmall.frame = 0
	if taser:
		$StunParticle.restart()

func _on_BulletImpact_animation_finished():
	$BulletImpact.hide()
