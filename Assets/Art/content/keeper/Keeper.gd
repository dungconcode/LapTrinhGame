extends CharacterBody2D

class_name Keeper

signal mined

@export var techId := ""
var playerId:String # player of this keeper, like player1, player2, ..

var disabled := false
var disable_source = null
var tutorialsActive := false
var showcaseMode := false
var killed := false

var usables := []
var carryables := []
var focussedUsable
var focussedCarryable

var moveDirectionInput := Vector2()
var aimDirectionInput := Vector2()
var move := Vector2()
var externallyMoved := false
const moveDirectionThreshold := 0.05
const mouseTooCloseThreshold := 15
var pickupType := ""

var animationSuffix := ""

var carriedCarryables := []

var isInsideDome:bool
var isInsideStation:bool
var virtuallyIsInsideDome:bool

var temporaryBuffs:Array[TemporaryBuff] = []


func init():
	if playerId == "":
		Logger.error("playerId is not set before initialising the keeper", "Keeper.init")
	Data.createInstanceProperties("keeper", playerId)
	Data.createInstanceProperties(techId, playerId)
	Achievements.addIfOpen(self, "KEEPER_BOTTOM")
	Achievements.addIfOpen(self, "KEEPER_TIMELY")
	Achievements.addIfOpen(self, "KEEPER_MARATHON")

	onShowKeeperAimIndicatorChanged()

func _physics_process(delta):
	if killed:
		return
	$Light3D.visible = position.y > 0
	$Light3D/LightBig.light_active = $Light3D.visible
	$Light3D/LightSmall.light_active = $Light3D.visible
	if not $Light3D/Tween.is_active():
		var s: float = randf_range(1.0, 1.05)
		$Light3D/Tween.interpolate_property($Light3D, "scale", $Light3D.scale, Vector2(s,s), 0.08, Tween.TRANS_CUBIC)
		$Light3D/Tween.start()
	
	var newIsInsideDome = virtuallyIsInsideDome or position.y < CONST.DOME_CELLAR_ENTRANCE_Y
	if newIsInsideDome != isInsideDome:
		var oldInsideDome = isInsideDome
		isInsideDome = newIsInsideDome
		Data.event("event.keepers.insidedome", oldInsideDome, newIsInsideDome)
	
	if not(isInsideStation or GameWorld.paused or disabled):
		var i := 0
		while i < temporaryBuffs.size():
			var buff := temporaryBuffs[i]
			buff.remainingDuration -= delta
			if buff.remainingDuration <= 0:
				Data.changeByInt(playerId + "." + buff.property, -buff.amount)
				temporaryBuffs.remove_at(i)
				continue
			i += 1

func addTemporaryBuff(property:String, amount, duration:float, origin:String):
	if amount == 0:
		# no effect
		return
	Data.changeByInt(playerId + "." + property, amount)
	var buff = TemporaryBuff.new()
	buff.property = property
	buff.amount = amount
	buff.remainingDuration = duration
	buff.origin = origin
	temporaryBuffs.append(buff)

func getTemporaryBuff(property:String, origin:String):
	for buff in temporaryBuffs:
		if property == buff.property and origin == buff.origin:
			return buff
	return null

func setSkin(skinId:String):
	var skinSpritePath : String = "res://content/keeper/" + techId + "/spriteframes-" + skinId + ".tres"
	$Sprite2D.sprite_frames = load(skinSpritePath)

func exitStation():
	if not GameWorld.lost:
		# If the game is lost while the keeper is inside the station, he will
		# automatically exit when the InputProcessor is desintegrated.
		# To prevent the keeper appearing in the destroyed dome, check for this.
		visible = true

	isInsideStation = false
	Data.event("event.keepers.insidestation")
	$Trail.visible = true
	$Sprite2D.visible = true
	enableEffects()

func enterStation(dropResources := true):
	$Sprite2D.visible = false
	$Trail.restart()
	$Trail.visible = false
	disableEffects()
	move *= 0.0
	position = focussedUsable.get_parent().getKeeperPosition() + Vector2(0.5,0)
	isInsideStation = true
	Data.event("event.keepers.insidestation")
	
	if dropResources:
		for c in carriedCarryables.duplicate():
			if not c.get_collision_mask_value(CONST.LAYER_DOME_EXTERNAL):
				# Layer 10 blocks carryables from entering the dome. Stuff like probe and teleporter. 
				# If not entering the dome, the carryable shouldn't go into the independent mode, moving towards a dome target.
				
				# avoid large packed resources getting stuck on the way up
				if c.carryableType == "resource" and c.type == "pack":
					c.set_collision_mask_value(CONST.LAYER_DROP_DOME_BORDER, false)
					c.set_collision_mask_value(CONST.LAYER_DROP_COLLISION, false)
				c.setIndependent(true)
				c.dropTargetRef = Level.dome.getDropTarget(c.type)
				dropCarry(c)

func _on_CarryArea_body_entered(carryable):
	if carryables.has(carryable):
		return
	
	carryables.append(carryable)

func _on_CarryArea_body_exited(carryable):
	carryables.erase(carryable)

func _on_UseArea_usable_entered(usable):
	if usables.has(usable):
		return
	
	usables.append(usable)

func _on_UseArea_usable_exited(usable):
	usables.erase(usable)

func dropCarry(body):
	pass

func updateInteractables():
	updateUsables()
	updateCarryables()

func updateUsables():
	if not is_instance_valid(focussedUsable):
		focussedUsable = null
	
	if focussedUsable:
		if usables.has(focussedUsable):
			if focussedUsable.canFocusUse(self):
				return
			else:
				focussedUsable.unfocusUse(self)
				focussedUsable = null
		else:
			focussedUsable.unfocusUse(self)
			focussedUsable = null
	else:
		for usable in usables:
			if usable.canFocusUse(self):
				focussedUsable = usable
				usable.focusUse(self)
				break

func updateCarryables():
	pass

func sortByDistance(b1, b2):
	return (b1.global_position - global_position).length() < (b2.global_position - global_position).length()

func useHit() -> bool:
	if isInsideStation or disabled:
		return false
	
	if focussedUsable and is_instance_valid(focussedUsable):
		var handled = focussedUsable.useHit(self)
		if handled:
			return true
	
	return false

func useHold() -> bool:
	if isInsideStation or disabled:
		return false
	
	if focussedUsable:
		return focussedUsable.useHold(self)
	
	return false

func useTryCancelDisable():
	if disabled and disable_source:
		if disable_source.has_method("keeperWantsToAbort"):
			disable_source.keeperWantsToAbort(self)
			if focussedUsable:
				focussedUsable.updateFocus()

func onGameLost():
	$UseArea.monitoring = false
	if focussedUsable:
		focussedUsable.unfocusUse(self)
		focussedUsable = null
	if focussedCarryable:
		focussedCarryable.unfocusCarry(self)
		focussedCarryable = null
	disabled = true
	
	visible = false

func teleport(pos:Vector2):
	if focussedUsable:
		focussedUsable.unfocusUse(self)
		focussedUsable = null
	move *= 0.0
	moveDirectionInput *= 0.0
	position = pos
	for c in carriedCarryables:
		c.teleport(pos + Vector2.UP.rotated(randf_range(-PI, PI)) * (3 + randf() * 7))

func startTeleportation(source, duration:float, fromPos:Vector2, goalPos:Vector2, allowCarryableTeleportation:bool, allowLargeDropTeleportation := false):
	$TeleportInit.play()
	for c in carriedCarryables.duplicate():
		if not (allowCarryableTeleportation and c.canTeleport) and not (allowLargeDropTeleportation and not c.canTeleport and (c.type == "powercore" or c.type == "gadget")):
			dropCarry(c)
	disabled = true
	disable_source = source
	
	disableEffects()
	$Sprite2D.play("default"+animationSuffix)
	var teleportColor : Color = Style.mapColor(Color("#304c8c"))*2.0
	teleportColor.a = 1.0
	$Tween.interpolate_property($Sprite2D, "modulate", $Sprite2D.modulate, teleportColor, duration, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_property(self, "position", position, fromPos, duration - 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.start()

	var cameraAnimationDelay = duration * 0.75
	Level.viewports.startTeleportAnimation(self, duration, fromPos, goalPos, cameraAnimationDelay)

func teleportComplete():
	$Tween.remove_all()
	find_child("Light3D").scale = Vector2.ZERO
	$Sprite2D.modulate.a = 0.0
	visible = false

func grow(duration:float, delay := 0.0):
	$Tween.interpolate_property(find_child("Light3D"), "scale", Vector2.ZERO, Vector2.ONE, duration, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, delay)
	$Tween.interpolate_property($Sprite2D, "modulate:a", 0.0, 1.0, 0.4, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, duration+delay-0.4)
	$Tween.interpolate_property($Sprite2D, "modulate", $Sprite2D.modulate, Color.WHITE, duration, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, delay)
	$Tween.interpolate_callback(self, duration + delay - 0.55, "teleportArrive")
	$Tween.interpolate_callback(self, duration + delay - 0.1, "set", "disabled", false)
	$Tween.interpolate_callback(self, duration + delay - 0.1, "set", "disable_source", false)
	$Tween.interpolate_callback(self, duration + delay - 0.1, "enableEffects")
	$Tween.start()

func teleportArrive():
	visible = true
	var effect = preload("res://content/gadgets/teleporter/TeleportEffect.tscn").instantiate()
	add_child(effect)
	$TeleportDone.play()

func disableEffects():
	pass

func enableEffects():
	pass

func addAddition(addition):
	add_child(addition)

func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
	else:
		$Tween.resume_all()

func remove():
	disableEffects()
	visible = false
	if focussedUsable:
		focussedUsable.unfocusUse(self)
	if focussedCarryable:
		focussedCarryable.unfocusCarry(self)

func kill():
	killed = true
	remove()
	queue_free()

func onShowKeeperAimIndicatorChanged():
	pass

func onInputMethodChanged():
	onShowKeeperAimIndicatorChanged()

func getAimDirection() -> Vector2:
	if showcaseMode:
		return moveDirectionInput

	if Options.useGamepad:
		if aimDirectionInput.length() < moveDirectionThreshold:
			return Vector2.ZERO
		else:
			return Data.snapVectorToDirections(aimDirectionInput, deg_to_rad(Options.keeperGamepadSnapDirectionDegrees * 0.5))
	elif Options.useMouseKeeperGameplay:
		var localMousePosition = get_local_mouse_position()
		if localMousePosition.length() < mouseTooCloseThreshold:
			return Vector2.ZERO
		else:
			return Data.snapVectorToDirections(localMousePosition, deg_to_rad(Options.keeperMouseSnapDirectionDegrees * 0.5))
	else:
		return moveDirectionInput

func canEnterRemoteStation() -> bool:
	return true

func move_and_slide_custom():
	var dt = get_physics_process_delta_time()
	
	var prevv = velocity
	var c = move_and_collide(velocity * dt, false, safe_margin)

	if c:
		#this is not physically correct but feels right
		var lost_velocity = prevv -  c.get_remainder() - (c.get_travel()/dt)
		#project lost movement onto the surface tangent of the collision
		var slide_dir =  c.get_normal().rotated(Const.PI_HALF)
		var projected_slide = lost_velocity.dot(slide_dir) * slide_dir
		#slide with the remaining movement
		move_and_collide(projected_slide * dt, false, safe_margin)
		
		#remove volocity lost through collision
		velocity = prevv - c.get_normal() *  prevv.dot(c.get_normal())
