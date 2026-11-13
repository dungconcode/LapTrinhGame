extends Carryable

class_name Drop

@export var type := ""
@export var stabilizeRotation := false
@export var hasInterDropCollisionSound := false
@export var floatUncarried := false
@export var independentSpeedClamp := 2.0
@export var independentAcceleration := 1.0
@export var arrivalDistanceToTarget := 3.0

var absorbed := false
var dropTargetRef
var dropTargetPosition:Vector2
var stabilizationForce := 1.0
var domeEnterPosition:float
var bounciness:float
var dropSoundCooldown := 0.0

var independantTimeSinceLastMove := 0.0
var lastIndependantPos :Vector2

var lastCollisions := {}

func _ready():
	super._ready()
	
	if hasInterDropCollisionSound:
		connect("body_entered", Callable(self, "_on_Drop_body_entered"))
	
	# remember bounciness, as it is set to 0 when the body rests. Otherwise, bodies won't stop moving.
	bounciness = physics_material_override.bounce
	
	Style.init(self)
	
	Data.changeByInt("inventory.floating" + type, 1)
	Data.changeByInt("inventory.total" + type, 1)

func onCarried(p):
	can_sleep = false
	pass

func onDropped(p):
	can_sleep = true
	Utils.wakeUpDrop(self, true)
	pass

func _physics_process(delta):
	if GameWorld.paused and not independent:
		return
	for c in lastCollisions.duplicate():
		var d = lastCollisions[c] - delta
		if d <= 0:
			lastCollisions.erase(c)
		else:
			lastCollisions[c] = d

	if dropSoundCooldown > 0.0:
		dropSoundCooldown -= delta
	
	if not isCarried():
		if independent and dropTargetRef:
			var dist = independentAcceleration * (dropTargetRef.dropTarget() - position)
			if dist.length() < arrivalDistanceToTarget and not absorbed:
				dropTargetRef.arrived(self)
			# needs to separate the axis, as otherwise resources might get stuck underneath the dome
			# when the strong upwards direction does "block" the sideways movement
			apply_central_impulse(Vector2(0, dist.y).limit_length(independentSpeedClamp))
			apply_central_impulse(Vector2(dist.x, 0).limit_length(independentSpeedClamp))
			if not deactivated:
				deactivate()
			
			processIndependantStuckResolver(delta)
			
		elif floatUncarried and not hasCarryInfluence():
			apply_central_impulse(-linear_velocity.limit_length(3.0))
	
	if independent and not dropTarget and not deactivated:
		deactivate()
		gravity_scale = 0.1
	
	if not deactivated and not independent:
		if linear_velocity.length() > 4.0:
			physics_material_override.call_deferred("set_bounce", bounciness)
		else:
			physics_material_override.call_deferred("set_bounce", 0.0)
	
	if stabilizeRotation:
		var drot = 0.0 - rotation
		apply_torque_impulse(drot * stabilizationForce)

#if drops get stuck for too long while independant we disable collision and let one phase through
func processIndependantStuckResolver(delta):
	var p = position
	if is_equal_approx(lastIndependantPos.x,p.x) and is_equal_approx(lastIndependantPos.y, p.y):
		independantTimeSinceLastMove += delta
		if independantTimeSinceLastMove > 1.0:
			set_collision_mask_value(CONST.LAYER_DROP_COLLISION, false)
	else:
		independantTimeSinceLastMove = 0.0
		lastIndependantPos = p

func floatToDropTarget(inDropTarget):
	if independent:
		return
	
	dropTargetRef = inDropTarget
	setIndependent(true)
	if isCarried():
		for k in carriedBy:
			if k:
				# made lift crash
				k.dropCarry(self)

func deactivate():
	set_collision_layer_value(CONST.LAYER_USABLES, false)
	set_collision_mask_value(CONST.LAYER_USABLES, false)
	deactivated = true
	var po = CarryablePhysicsOverride.new(self)
	po.gravity_scale = 0.0
	po.linear_damp = 2
	po.angular_damp = 2
	addPhysicsOverride(po)
	physics_material_override.call_deferred("set_bounce", 0.0)
	if (type == CONST.GADGET or type == CONST.POWERCORE) and not absorbed:
		$CollisionShape2D.set_deferred("disabled", true)
		if not GameWorld.gameover:
			Level.stage.startGadgetChoiceInput(type)
		gravity_scale = 0.0
		remove_from_group("saveable")

func remove():
	if absorbed:
		return
	
	absorbed = true
	Data.changeByInt("inventory.floating" + type, -1)
	queue_free()

var shrinkTween : Tween
func shrink():
	if absorbed:
		return
	
	if dropTargetRef:
		dropTargetPosition = dropTargetRef.dropTarget()
		dropTargetRef = null
	
	absorbed = true
	var outDuration := 0.6
	linear_damp = 13 #so drop won't move a lot while being shredded
	
	if shrinkTween:
		shrinkTween.kill()
	shrinkTween = create_tween()
	shrinkTween.set_parallel().tween_property($Sprite2D, "scale", Vector2.ZERO, outDuration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	shrinkTween.tween_property(self, "position", dropTargetPosition, outDuration - 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	shrinkTween.tween_callback(Data.changeByInt.bind("inventory." + type, 1)).set_delay(outDuration*0.6)
	shrinkTween.tween_callback(queue_free).set_delay(outDuration)
	Data.changeByInt("inventory.floating" + type, -1)
	
	if is_in_group("saveable"):
		remove_from_group("saveable")

var shredTween : Tween
func shred(addToInventory := true):
	if absorbed:
		return
	
	if dropTargetRef:
		dropTargetPosition = dropTargetRef.dropTarget()
		dropTargetRef = null
	
	absorbed = true
	var outDuration := 0.6
	var particle_lifetime = 0
	linear_damp = 13 #so drop won't move a lot while being shredded
	
	if shredTween:
		shredTween.kill()
	shredTween = create_tween()
	if has_node("ShredParticles"):
		for child in get_node("ShredParticles").get_children():
			particle_lifetime = max(particle_lifetime, child.lifetime)
			child.emitting = true
			shredTween.tween_callback(child.set_emitting.bind(false)).set_delay(outDuration)
		shredTween.set_parallel().tween_property($Sprite2D, "modulate:a", 0, outDuration)
	else:
		shredTween.set_parallel().tween_property($Sprite2D, "scale", Vector2.ZERO, outDuration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if addToInventory:
		shredTween.tween_callback(Data.changeByInt.bind("inventory." + type, 1)).set_delay(outDuration*0.6)
	Data.changeByInt("inventory.floating" + type, -1)
	
	# Adding particle_lifetime so the particles get time to finish their thing
	shredTween.tween_callback(queue_free).set_delay(outDuration + particle_lifetime)
	
	if is_in_group("saveable"):
		remove_from_group("saveable")

func _on_Drop_body_entered(body):
	if lastCollisions.has(body):
		lastCollisions[body] = 1.0
		return
	
	if dropSoundCooldown > 0.0:
		return
	
	if $BumpSound.playing:
		return
	
	var other_velocity = body.get('linear_velocity')
	if other_velocity == null:
		other_velocity = Vector2.ZERO
	var relative_velocity = linear_velocity - other_velocity
	if relative_velocity.length() > 2.0:
		$BumpSound.additionalVolume = -6 + 6 * min(1.5, relative_velocity.length() / 12.0 )
#		$BumpSound.additionalVolume = (9  + 9 * min(2.0, relative_velocity.length() / 14.0 ))
		$BumpSound.play()
		dropSoundCooldown = 0.3
		lastCollisions[body] = 0.4

func moveToPhysicsBackLayer():
	modulate = Color(0.8,0.8, 0.8, 1)
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(CONST.LAYER_BACK_LAYER_COLLISIONS, true)
	set_collision_mask_value(CONST.LAYER_BACK_LAYER_COLLISIONS, true)

func moveToPhysicsFrontLayer():
	modulate = Color.WHITE
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(CONST.LAYER_DROP_COLLISION, true)
	set_collision_mask_value(CONST.LAYER_DROP_COLLISION, true)
	set_collision_layer_value(CONST.LAYER_CARRYABLES, true)
	set_collision_layer_value(CONST.LAYER_LIFT_RIGID, true)
	set_collision_mask_value(CONST.LAYER_DROP_DOME_BORDER, true)

func noCollisions():
	set_collision_layer_value(CONST.LAYER_BACK_LAYER_COLLISIONS, false)
	set_collision_mask_value(CONST.LAYER_BACK_LAYER_COLLISIONS, false)
	set_collision_layer_value(CONST.LAYER_DROP_COLLISION, false)
	set_collision_mask_value(CONST.LAYER_DROP_COLLISION, false)

func dropTarget():
	return dropTargetPosition
