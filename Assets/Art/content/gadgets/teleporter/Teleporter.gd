extends Carryable

var gravity:Vector2
var off:=Vector2()
var station
var resourcesInSucker := []
var currentlySuckedResource
var originalAccel
var originalSpeedClamp
var suckCooldown := 0.0
var shake := 0.0
var pullCountdown := 0.0
var teleporting := false

func _ready():
	super._ready()
	$Sprite2D.play("ready")
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	Data.listen(self, "teleporter.teleportResources")
	Data.listen(self, "teleporter.teleportResourcesArea", true)
	Data.listen(self, "teleporter.slowdown", true)
	$ResourceSucker/CollisionShape2D.disabled = not Data.of("teleporter.teleportResources")
	$"%SuckLine".visible = false
	Style.init(self)
	
	Level.addTutorial(self, "teleporter_teleport")
	Level.addTutorial(self, "teleporter_carry")

func serialize()->Dictionary:
	var data = super.serialize()
	data["pullCountdown"] = pullCountdown
	data["suckCooldown"] = suckCooldown
	return data

func deserialize(data: Dictionary):
	super.deserialize(data)
	pullCountdown = data["pullCountdown"]
	suckCooldown = data["suckCooldown"]
		
func propertyChanged(property:String, oldValue, newValue):
	match property:
		"teleporter.slowdown":
			additionalSlowdown = newValue
		"teleporter.teleportresources":
			$ResourceSucker/CollisionShape2D.disabled = not newValue
		"teleporter.teleportresourcesarea":
			$ResourceSucker/CollisionShape2D.shape.radius = newValue * GameWorld.TILE_SIZE

func onCarried(p:Keeper):
	if currentlySuckedResource:
		arrived(currentlySuckedResource)

func onDropped(keeper:Keeper):
	# was focussing on a fixed tile before, but there is an offset error somewhere - probably with the map methods called here
#	var coord = Level.map.getTileCoord(position)
#	targetPos = Level.map.getTilePos(coord)
	pass

func _physics_process(delta):
	if isCarried():
		return
	
	apply_central_impulse(-linear_velocity.limit_length(max(1.0, linear_velocity.length() * 0.025)))
	off.y = sin(0.01*Time.get_ticks_msec()) * 1.3
	apply_central_impulse(off)
#	if shake > 0.0:
#		apply_torque_impulse(shake*(-0.5+randf()))
#	else:
	var drot = 0.0 - rotation
	apply_torque_impulse(drot * 3.0)
	
	if GameWorld.paused:
		return
	
	if suckCooldown > 0.0:
		suckCooldown -= delta * GameWorld.cycleSpeed
		return
	elif $Sprite2D.animation != "active":
		$Sprite2D.play("ready")
	
	if $ResourceSucker/CollisionShape2D.disabled:
		return
	
	if not currentlySuckedResource:
		var closestDistance := 9999.0
		var closestResource : Node = null
		for resource in resourcesInSucker:
			if resource.isCarried() or not resource.canFocusCarry():
				continue
			var distance = resource.global_position.distance_to(global_position)
			if distance < closestDistance:
				closestDistance = distance
				closestResource = resource
		if closestResource:
			currentlySuckedResource = closestResource
			currentlySuckedResource.setIndependent(true)
			currentlySuckedResource.dissolveCarryInfluence()
			currentlySuckedResource.dropTargetRef = self
			originalAccel = currentlySuckedResource.independentAcceleration
			originalSpeedClamp = currentlySuckedResource.independentSpeedClamp
			startSuckAnimation()
			shake = 20.0
			pullCountdown = 0.0
			return
	
	if currentlySuckedResource:
		var suckProgress = clamp(pullCountdown/12.0, 0.01, 1.0)
		currentlySuckedResource.independentAcceleration = originalAccel * suckProgress * 80
		currentlySuckedResource.independentSpeedClamp = originalSpeedClamp * suckProgress * 80
		$"%SuckLine".set_point_position(1, currentlySuckedResource.global_position - global_position)
		pullCountdown += delta
		if pullCountdown > 16.0:
			arrived(currentlySuckedResource)


func _process(_delta):
	$Effects.global_rotation = 0.0

func dropTarget() -> Vector2:
	return global_position

func onTeleported(duration:float, delay := 0.0):
	$"%LightSmall".light_size = 0.1
	$"%LightBig".light_size = 0.1
	%TeleporterActiveParticle.emitting = true
	$Sprite2D.play("active")
	$"%LightTween".remove_all()
	# Spinup Phase
	$"%LightTween".interpolate_callback(self, delay, "startParticleEffects")
	$"%LightTween".interpolate_property($"%LightSmall", "light_size", 0.1, 44, duration, Tween.TRANS_SINE, Tween.EASE_OUT, delay)
	$"%LightTween".interpolate_property($"%LightBig", "light_size", 0.1, 64, duration, Tween.TRANS_SINE, Tween.EASE_OUT, delay)
	$"%LightTween".interpolate_property($"%LightSmall", "light_flicker_strength", 1, 6, duration, Tween.TRANS_SINE, Tween.EASE_OUT, delay)
	$"%LightTween".interpolate_property($"%LightBig", "light_flicker_strength", 1, 6, duration, Tween.TRANS_SINE, Tween.EASE_OUT, delay)
	$"%LightTween".interpolate_property($"%TeleporterActiveBg", "self_modulate:a", 0, 1, delay, Tween.TRANS_SINE, Tween.EASE_OUT)
	
	# Stopping phase
	$"%LightTween".interpolate_property($"%LightSmall", "light_size", 44, 0.1, 0.3, Tween.TRANS_SINE, Tween.EASE_OUT, delay+duration)
	$"%LightTween".interpolate_property($"%LightBig", "light_size", 64, 0.1, 0.3, Tween.TRANS_SINE, Tween.EASE_OUT, delay+duration)
	$"%LightTween".interpolate_property($"%LightSmall", "light_active", true, false, 0.01, Tween.TRANS_SINE, Tween.EASE_OUT, 0.3+delay+duration)
	$"%LightTween".interpolate_property($"%LightBig", "light_active", true, false, 0.01, Tween.TRANS_SINE, Tween.EASE_OUT, 0.3+delay+duration)
	$"%LightTween".interpolate_property($"%TeleporterActiveBg", "self_modulate:a", 1, 0, delay, Tween.TRANS_SINE, Tween.EASE_OUT, delay+duration)
	$"%LightTween".interpolate_callback(self, delay+duration, "stopParticleEffects")
	$"%LightTween".start()

func stopParticleEffects():
	$Sprite2D.play("cooldown")
	$Effects/AppearParticles2.emitting = false
	$Effects/AppearParticles.emitting = false
	$Effects/StartupParticles.emitting = false
	$Effects/StartupParticles2.emitting = false
	$"%TeleporterActiveParticle".emitting = false

func startParticleEffects():
	$"%LightSmall".light_active = true
	$"%LightBig".light_active = true
	$Effects/AppearParticles2.emitting = true
	$Effects/AppearParticles.emitting = true
	$Effects/StartupParticles.emitting = true
	$Effects/StartupParticles2.emitting = true

func stopSuckAnimation():
	if not $"%SuckLine".visible:
		return
	$Sprite2D.play("cooldown")
	$"%LightTween".interpolate_property($"%TeleporterActiveBg", "self_modulate:a", 1, 0, 0.3, Tween.TRANS_SINE, Tween.EASE_OUT, 0.3)
	$"%LightTween".interpolate_callback($"%TeleporterActiveParticle", 0.3, "set_emitting", false)
	$"%LightTween".start()
	$"%SuckLine".visible = false
	$Effects/StartupParticles.emitting = false
	$Effects/StartupParticles2.emitting = false
	$"%LightSmall".light_active = false
	$"%LightBig".light_active = false
	$ResourcePull.stop()
	$ResourcePullStop.play()

func startSuckAnimation():
	$ResourcePull.play()
	$"%SuckLine".visible = true
	$Effects/StartupParticles.emitting = true
	$Effects/StartupParticles2.emitting = true
	$Sprite2D.play("active")
	$"%TeleporterActiveParticle".emitting = true
	$"%LightTween".remove_all()
	$"%LightTween".interpolate_property($"%LightSmall", "light_size", 5, 20, 0.3, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%LightTween".interpolate_property($"%LightBig", "light_size", 5, 28, 0.3, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%LightTween".interpolate_property($"%LightSmall", "light_flicker_strength", 1, 2, 0.3, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%LightTween".interpolate_property($"%LightBig", "light_flicker_strength", 1, 2, 0.3, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%LightTween".interpolate_property($"%TeleporterActiveBg", "self_modulate:a", 0, 1, 0.15, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%LightTween".start()
	$"%LightSmall".light_active = true
	$"%LightBig".light_active = true

func animateTeleportation(lenght:=1.0, use_timer:=true):
	$Sprite2D.play("active")
	$"%TeleporterActiveParticle".emitting = true
	$Effects/StartupParticles.emitting = true
	$Effects/StartupParticles2.emitting = true
	$"%LightTween".remove_all()
	$"%LightTween".interpolate_property($"%LightSmall", "light_size", 5, 44, lenght, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%LightTween".interpolate_property($"%LightBig", "light_size", 5, 64, lenght, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%LightTween".interpolate_property($"%LightSmall", "light_flicker_strength", 1, 6, lenght, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%LightTween".interpolate_property($"%LightBig", "light_flicker_strength", 1, 6, lenght, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%LightTween".interpolate_callback($Sprite2D, lenght, "set_animation", "ready")
	$"%LightTween".interpolate_callback($"%TeleporterActiveParticle", lenght, "set_emitting", false)
	$"%LightTween".interpolate_property($"%TeleporterActiveBg", "self_modulate:a", 0, 1, 0.3, Tween.TRANS_SINE, Tween.EASE_OUT)
	$"%LightTween".interpolate_property($"%TeleporterActiveBg", "self_modulate:a", 1, 0, 0.3, Tween.TRANS_SINE, Tween.EASE_OUT, lenght)
	$"%LightTween".start()
	$"%LightSmall".light_active = true
	$"%LightBig".light_active = true
	if use_timer:
		$AnimationTimer.start(Data.of("teleporter.teleportDuration"))


func canFocusUse(keeper:Keeper) -> bool:
	return not teleporting and Data.of("teleporter.teleportBack") and carriedBy.size() == 0

func useHit(keeper:Keeper) -> bool:
	if position.y > 50 and Data.of("teleporter.teleportBack"):
		teleporting = true
		unfocusCarry(keeper)
		var shrinkTime: float = min(2.0, Data.of("teleporter.teleportDuration") * 0.33)
		var transitionTime:float = Data.of("teleporter.teleportDuration") - (2 * shrinkTime)
		keeper.startTeleportation(self, shrinkTime, $CollisionShape2D.global_position, get_tree().get_nodes_in_group("cameras").front().getDomeRestPos(), Data.ofOr("teleporter.teleportitems", false))
		animateTeleportation(shrinkTime, false)
		
		$TeleportationTimer.interpolate_callback(self, shrinkTime, "complete_teleport", false, shrinkTime, transitionTime, keeper)
		$TeleportationTimer.start()
		return true
	else:
		return false

func keeperWantsToAbort(keeper:Keeper):
	if not teleporting:
		return
	
	$TeleportationTimer.stop_all()
	$TeleportationTimer.remove_all()
	%LightTween.stop_all()
	complete_teleport(true, 0, 0.2, keeper)

func getTeleportPosition() -> Vector2:
	return global_position+Vector2(0,4)

func useHold(keeper:Keeper) -> bool:
	return false

func canTeleportDrop(body):
	return body.type == CONST.IRON \
	or body.type == CONST.WATER \
	or body.type == CONST.SAND \
	or body.type == "pack"

func _on_ResourceSucker_body_entered(body):
	if canTeleportDrop(body):
		resourcesInSucker.append(body)

func _on_ResourceSucker_body_exited(body):
	if canTeleportDrop(body):
		resourcesInSucker.erase(body)

func arrived(res):
	if res == currentlySuckedResource:
		res.shrink()
		$ResourceTeleport.play()
		currentlySuckedResource = null
		suckCooldown = Data.of("teleporter.teleportResourcesCooldown")
		$AnimationTimer.start(0.5)

func pauseChanged():
	super.pauseChanged()
	$AnimationTimer.paused = GameWorld.paused
	if GameWorld.paused and not independent:
		$TeleportationTimer.stop_all()
	else:
		$TeleportationTimer.resume_all()

func isTeleporting() -> bool:
	return teleporting

func _on_AnimationTimer_timeout():
	shake = 0.0
	stopSuckAnimation()
	$Effects/TeleportEffect.frame = 11 #last frame
	$Sprite2D.offset = Vector2.ZERO
	$Sprite2D.play("cooldown")


func complete_teleport(aborted:bool, shrinkTime:float, transitionTime:float, keeper:Keeper):
	$Effects/StartupParticles.emitting = false
	$Effects/StartupParticles2.emitting = false
	$Effects/TeleportEffect.frame = 0
	$Effects/TeleportEffect.play()
	$Effects/UseParticles.restart()
	$Effects/UseParticles.emitting = true
	$"%LightSmall".light_active = false
	$"%LightBig".light_active = false
	%TeleporterActiveParticle.emitting = false
	%TeleporterActiveBg.self_modulate.a = 0
	keeper.teleportComplete()
	if not aborted:
		keeper.teleport(station.teleportPosition())
		station.onTeleported(shrinkTime, transitionTime - 0.2)
	else:
		Level.viewports.abortTeleportAnimation(keeper)
	keeper.grow(shrinkTime, transitionTime - 0.2)
	$Sprite2D.play("cooldown")
	teleporting = false
