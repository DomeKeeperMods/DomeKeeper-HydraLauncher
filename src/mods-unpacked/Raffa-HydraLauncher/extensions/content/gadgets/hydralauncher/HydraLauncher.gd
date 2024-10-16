extends Node2D

const INITIAL_ANGLES : Array = [-0.4, -0.15, 0.15, 0.4]

var rechargeTime:float
var maxRechargeTime:float

var maxProjectiles := 2
var projectiles := 0
var damage := 2.0
var isActive := false
var missileId := 0
var missileSalvoCount := 0
var fired := 0
var autotrackerReload := 0.0
var autotrackerReloadTime := 1.2
var validTargets := []
var tween : Tween

@onready var reloadProgress = $Visuals/Base/ReloadProgress
@onready var ammo = [$Visuals/Ammo1, $Visuals/Ammo2, $Visuals/Ammo3, $Visuals/Ammo4]
@onready var ammoLamps = [$Visuals/Ammo1/Lamp, $Visuals/Ammo2/Lamp, $Visuals/Ammo3/Lamp, $Visuals/Ammo4/Lamp]

# This Mod example handles adding a new Gadget that charges up missiles (charge speed upgradeable)
# The player can then shoot missiles during waves

func _ready():
	# Add to the group "dome_ability2" top make it usable in combat
	add_to_group("dome_ability2")
	
	# Initialize this node and all it's first level children with Styling / Palette swap
	Style.init(self)
	
	# Listening to changes from a property in Data:
	# See the comment above `listen` in `Data` to get boilerplate code for the function
	Data.listen(self, "hydralauncher.maxprojectiles", true)
	Data.listen(self, "hydralauncher.projectiles", true)
	Data.listen(self, "hydralauncher.rechargetime", true)
	Data.listen(self, "hydralauncher.autotrackingreload", true)
	rechargeTime = maxRechargeTime

# This function is called when a property in `Data` changes
func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"hydralauncher.projectiles":
			projectiles = int(newValue)
			changeAmmo()
		"hydralauncher.maxprojectiles":
			maxProjectiles = int(newValue)
		"hydralauncher.rechargetime":
			maxRechargeTime = newValue
		"hydralauncher.autotrackingreload":
			autotrackerReloadTime = newValue

func activate():
	if not isActive:
		isActive = true
		vfxActivation()

func deactivate():
	if isActive:
		isActive = false
		vfxDeactivation()

func _physics_process(delta):
	# Pausing has to be implemented manually in Dome Keeper
	if GameWorld.paused:
		return
	
	if isActive:
		if not Keepers.oneInsideStation():
			deactivate()
	else:
		if Keepers.oneInsideStation():
			activate()
	
	getValidTargets()
	handleReloading(delta)
	
	# Code for Autotracker Upgrade
	autotrackerReload = clamp(autotrackerReload-delta, 0, autotrackerReloadTime)
	if isActive and autotrackerReload <= 0 and Data.of("hydraLauncher.autotracking") and validTargetExists():
		autotrackerReload = autotrackerReloadTime
		shootMissile(false)

func executeBattle2() -> bool:
	if projectiles <= 0:
		Audio.sound("gui_err")
		return false
	Data.apply("hydralauncher.projectiles", projectiles - 1)
	shoot()
	Backend.event("battle_ability_used", {"gadget": "hydralauncher", "ability": "shoot"})
	return true

func handleReloading(delta):
	if rechargeTime > 0.0:
		rechargeTime -= delta
		reloadProgress.value = abs(1.0-(rechargeTime / maxRechargeTime))
		if rechargeTime <= 0.0:
			# Reload one projectile
			var projectilesPerCycle = Data.of("hydraLauncher.projectilePerCycle")
			Data.apply("hydralauncher.projectiles", clamp(projectiles+projectilesPerCycle, 0, maxProjectiles))

func changeAmmo():
	if not projectiles >= maxProjectiles and rechargeTime <= 0.0:
		rechargeTime = maxRechargeTime
	var recharge_tween := create_tween()
	var ammoId := 0
	for al in ammo:
		if ammoId >= projectiles:
			ammoLamps[ammoId].hide()
			var newPos = 3 if al.is_in_group("hydraAmmoLeft") else -3
			if abs(al.position.x) <= abs(newPos):
				recharge_tween.tween_property(al, "position:x", newPos, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
		else:
			ammoLamps[ammoId].show()
			if abs(al.position.x) > 0:
				recharge_tween.tween_property(al, "position:x", 0.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
		ammoId += 1

func shoot():
	missileSalvoCount += Data.of("hydraLauncher.projectileSalvo")
	$ShootTimer.start()

# This function is responsible for the display name shown in the UI in combat mode
func getBattleAbilityName() -> String:
	return tr("upgrades.hydralauncher.title")

func vfxActivation():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property($Visuals/Top, "position:y", -9, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)


func vfxDeactivation():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property($Visuals/Top, "position:y", 0, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE).set_delay(0.2)


func _on_ShootTimer_timeout():
	shootMissile()

func shootMissile(useSalvo:=true):
	var angle = INITIAL_ANGLES[wrapi(fired, 0, 3)]
	
	var newMuzzleflash = preload("res://mods-unpacked/Raffa-HydraLauncher/extensions/content/gadgets/hydralauncher/HydraMuzzleflash.tscn").instantiate()
	newMuzzleflash.rotation = $"%LaunchPos".rotation + angle
	$Visuals/Top.add_child(newMuzzleflash)
	newMuzzleflash.global_position = $"%LaunchPos".global_position
	
	var newMissile = preload("res://mods-unpacked/Raffa-HydraLauncher/extensions/content/gadgets/hydralauncher/HydraMissile.tscn").instantiate()
	newMissile.launcher = self
	newMissile.position = $"%LaunchPos".global_position
	newMissile.rotation = $"%LaunchPos".rotation + angle
	newMissile.direction = Vector2.UP.rotated(angle)
	newMissile.damage = Data.of("hydralauncher.damage")
	Level.map.add_child(newMissile)
	
	$ShotSound.play()
	
	if not useSalvo:
		return
	
	missileSalvoCount -= 1
	fired += 1
	if missileSalvoCount > 0:
		$ShootTimer.start()

func validTargetExists():
	for m in get_tree().get_nodes_in_group("monster"):
		if isTargetValid(m):
			return true
	return false

func isTargetValid(m):
	return !(m.invulnerable or m.dead or m.leaving or !m.hittable)

func getValidTargets():
	validTargets.clear()
	var monsters : Array = get_tree().get_nodes_in_group("monster")
	for m in monsters:
		if isTargetValid(m):
			validTargets.append(m)

func getNewTarget():
	if validTargets.is_empty():
		return null
	return validTargets[randi()%validTargets.size()]
