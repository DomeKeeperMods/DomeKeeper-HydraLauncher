extends Area2D

export (OpenSimplexNoise) var noise : OpenSimplexNoise

const maxSpeed := 350.0
const minSpeed := 150.0

var launcher : Node2D = null
var target : Node2D = null
var damage := 4.0
var fuse := 0.0
var fuseTime := 0.5
var fuseActive := false
var direction := Vector2.UP
var speed := 150.0
var lifetime := 0.0
var maxLifetime := 5.0
var trackingPower := 0.0
var trackingSpeed := 3.0
var selfDestructing := false
var exploded := false
var smoke : Node2D = null
var smokeDisappearing := false

onready var noiseOffset := randf()
onready var lastPoint := global_position
onready var flash = $Flash


func _ready():
	Style.init(self)
	smoke = preload("res://content/weapons/artillery/BulletSmoke.tscn").instance()
	smoke.material = preload("res://content/weapons/artillery/MortarSmokeMat.material")
	smoke.material = smoke.material.duplicate()
	Level.map.addPixelEffect(smoke)
	smoke.position = Vector2.ZERO
	smoke.points[0] = global_position
	smoke.points[1] = global_position
	smoke.modulate.r = randf()
	smoke.modulate.g = randf()
	Style.init(smoke)
	$Tween.interpolate_property(smoke, "modulate:b", 1, 0, 0.05, Tween.TRANS_SINE, Tween.EASE_IN)
	$Tween.start()

func _physics_process(delta):
	if GameWorld.paused or exploded:
		return
	
	if not target:
		target = launcher.getNewTarget()
	
	if target and not isTargetValid(target):
		trackingPower = 0.0
		target = null
	
	var noisePower := 1.0
	if target and not selfDestructing:
		speed = clamp(speed+delta*200, minSpeed, maxSpeed)
		trackingPower = clamp(trackingPower+(delta/trackingSpeed), 0.0, 1.0) * min(lifetime*2.0, 1.0)
		var newDir : Vector2 = global_position.direction_to(target.getHitboxCenter())
		var distance = global_position.distance_to(target.getHitboxCenter())
		noisePower = clamp(range_lerp(distance, 0, 150, -0.3, 1), 0.3, 1)
		var curvePower = clamp(range_lerp(distance, 0, 150, 10, 4), 30, 4)
		direction = lerp(direction, newDir, (delta*curvePower*trackingPower)).normalized()
		maxLifetime = lifetime + 5.0
	else:
		speed = clamp(speed-delta*300, minSpeed, maxSpeed)
		direction = lerp(direction, Vector2.UP, delta).normalized()
	
	var noised : float = noise.get_noise_1d(noiseOffset*1000.0 + lifetime*300.0) * noisePower * 0.2 * clamp(lifetime*3, 0, 1)
	direction = direction.rotated(noised)
	
	lifetime += delta
	if not fuseActive and fuse >= fuseTime:
		fuseActive = true
		$CollisionShape2D.set_deferred("disabled", false)
	elif not fuseActive:
		fuse += delta
	position += direction*speed*delta
	rotation = direction.angle()
	flash.scale = Vector2(rand_range(0.2, 0.4), rand_range(0.2, 0.4))
	
	if lastPoint.distance_to(global_position) > 5.0:
		lastPoint = global_position
		smoke.add_point(global_position)
	else:
		smoke.points[-1] = global_position
	if smoke.get_point_count() > 100:
		smoke.remove_point(0)
	
	if not selfDestructing and lifetime > maxLifetime:
		selfDestructing = true
		killMissile(0.5)

func isTargetValid(m):
	return !(m.invulnerable or m.dead or m.leaving or !m.hittable)

func _on_HydraMissile_area_entered(area):
	if area.is_in_group("monster"):
		if not isTargetValid(area):
			return
	killMissile()

func killMissile(delay:=0.0):
	if not smokeDisappearing and is_instance_valid(smoke):
		smokeDisappearing = true
		var newTween : Tween = Tween.new()
		smoke.add_child(newTween)
		newTween.interpolate_property(smoke, "modulate:b", 0, 1, 0.8, Tween.TRANS_SINE, Tween.EASE_IN)
		newTween.interpolate_callback(smoke, 0.8, "queue_free")
		newTween.start()
	if delay > 0:
		$Tween.interpolate_callback(self, delay, "explode")
		$Tween.start()
	else:
		explode()

func explode():
	if exploded:
		return
	exploded = true
	var explosionVFX = preload("res://mods-unpacked/Raffa-HydraLauncher/extensions/content/gadgets/hydralauncher/HydraMissileExplosion.tscn").instance()
	explosionVFX.taser = Data.of("hydralauncher.taser")
	explosionVFX.position = global_position
	explosionVFX.rotation = rotation
	Level.map.addPixelEffect(explosionVFX)
	flash.hide()
	$Sprite.hide()
	$Impact.play()
	$Fizz.stop()
	for e in $ExplosionArea.get_overlapping_areas():
		if e.is_in_group("monster"):
			var stunDamage = damage * 0.05 if not Data.of("hydralauncher.taser") else damage*2.0
			e.hit(damage, stunDamage)

func _on_Impact_finished():
	queue_free()
