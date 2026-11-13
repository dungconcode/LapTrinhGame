extends Node2D

var rechargeTime:float
var maxRechargeTime:float

var remainingCapacity := 0.0
var maxCapacity := 0.0
var targettedProjectile
var charge := 0.0
var active := false

func _ready():
	Style.init(self)
	Data.listen(self, "spire.capacity", true)
	remainingCapacity = maxCapacity
	maxRechargeTime = Data.of("spire.rechargetime")
	rechargeTime = maxRechargeTime
	
	$SpireHead.play("off")
	$Shine.modulate.a = 0.0
	$Burst.visible = false
	$LoadedBulb.visible = false

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"spire.capacity":
			maxCapacity = newValue

func activate():
	if not active:
		active = true
		$SpireHead.play("turn_on")

func deactivate():
	if active:
		active = false
		remainingCapacity = 0
		charge = 0
		$SpireHead.play("turn_off")
		discharge()

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	if active:
		if not Data.of("monsters.wavepresent") or (not Keepers.oneInsideStation() and not Data.of("spire.autonomy")):
			deactivate()
	else:
		if Data.of("monsters.wavepresent") and (Keepers.oneInsideStation() or Data.of("spire.autonomy")):
			activate()
	
	var brightness = 1.5 + sin(Time.get_ticks_msec()/300.0) * 0.5
	$LoadingOverlay.modulate = Color(brightness,brightness,brightness,1)
	$Shine.modulate.a = charge * 0.15 * (sin(Time.get_ticks_msec()/300.0) * 0.5 + 1.5)
	
	if not active:
		charge = 0.0
		updateFilling()
		return
		
	if rechargeTime > 0.0:
		rechargeTime -= delta
		updateFilling()
		if rechargeTime <= 0.0:
			remainingCapacity = maxCapacity
			$LoadedBulb.visible = true
			$ChargedUpSound.play()
			$SpireHead.play(str(min(4, remainingCapacity)))
		else:
			return
	
	if not is_instance_valid(targettedProjectile) or not targettedProjectile.flying:
		targettedProjectile = null
	
	var tbs = Data.of("spire.timebetweenshots")
	if not active:
		charge = max(0.0, charge - delta)
	
	if charge <= 1.0:
		if charge <= 0.6 or targettedProjectile:
			charge = min(1.0, charge + delta * (1.0 / tbs))
	
	if targettedProjectile and charge >= 1.0:
		remainingCapacity -= 1
		var arc = preload("res://content/weapons/tesla/TeslaShockArc.tscn").instantiate()
		Level.viewports.addElement(arc)
		arc.visual = true
		arc.lifetime = 0.4
		arc.init($EmissionPoint.global_position, targettedProjectile.global_position)
		$ShotSound.play()
		
		if Data.of("spire.splitshot"):
			var amount = round(sqrt(targettedProjectile.damage) * (1.0 + Data.of("spire.splitadditionalprojectiles")))
			for i in clamp(amount, 2, 20):
				var p = preload("res://content/gadgets/spire/SpireSplitShot.tscn").instantiate()
				p.setToDamageMonsters()
				p.position = targettedProjectile.global_position
				p.origin = p.position
				var circ = PI if Data.of("spire.splitshotground") else PI * 0.7
				p.target = Vector2.UP.rotated(randf_range(-circ, circ)) * 1200
				p.damage = Data.of("spire.splitshotdamage")
				p.speed = Data.of("spire.splitshotspeed")
				Level.viewports.addElement(p)
		elif Data.of("spire.stuntrap"):
			var trap = preload("res://content/gadgets/spire/Energytrap.tscn").instantiate()
			trap.position = targettedProjectile.global_position
			Level.viewports.addElement(trap)
			trap.start(targettedProjectile.damage)
		
		targettedProjectile.domeReflectsDamage(100)
		charge = 0.0
		
		if remainingCapacity <= 0:
			discharge()
			
		$SpireHead.play(str(min(4, remainingCapacity)))
	else:
		targettedProjectile = getClosesProjectile()

func updateFilling():
	var filling  = round(34 * (1.0 - max(0.0, rechargeTime / maxRechargeTime)))
	$LoadingOverlay.region_rect.size.y = filling
	$LoadingOverlay.offset.y = 34 - filling
	$LoadingOverlay.region_rect.position.y = $LoadingOverlay.offset.y
		
func discharge():
	maxRechargeTime = Data.of("spire.rechargetime")
	rechargeTime = maxRechargeTime * 0.1
	$Tween.interpolate_property(self, "rechargeTime", rechargeTime, maxRechargeTime, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.start()
	$LoadedBulb.visible = false
	$Burst.visible = true
	$Burst.frame = 0
	$Burst.play("burst")

func getClosesProjectile():
	var closestProjectile
	var closestDistance:float = 9999.0
	for p in get_tree().get_nodes_in_group("projectile"):
		if p.flying and p.position.length() < closestDistance:
			closestDistance = p.position.length()
			closestProjectile = p
	return closestProjectile


func _on_SpireHead_animation_finished():
	if $SpireHead.animation == "turn_on":
		$SpireHead.play(str(min(4, remainingCapacity)))
