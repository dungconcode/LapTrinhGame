extends Area2D

@onready var particles := $CollisionShape2D/GPUParticles2D
const LiftOrb = preload("res://content/gadgets/lift/LiftOrb.tscn")

var liftedRigids := []
var tileLength:int = -1
var orbCooldown:float
var keeperInsideLift := false
var addedSpeedPerPlayerId := {}
var orbState = []
var queuedOrbs = 0

func _ready():
	$build.play("default")
	$build.hide()
	
	Data.listen(self, "lift.useorbs", true)
	Data.listen(self, "lift.orbs", true)
	
	Style.init(self)
	
	Achievements.addIfOpen(self, "LIFT_JAM")
	Achievements.addIfOpen(self, "LIFT_TRANSPORT")

func serialize()->Dictionary:
	orbState = []
	for lo in get_tree().get_nodes_in_group("lift_orbs"):
		orbState.append(lo.serialize())
		
	var data = {
		"tileLength": tileLength,
		"orbState": orbState,
		"keeperInsideLift": keeperInsideLift,
		"addedSpeedPerPlayerId": addedSpeedPerPlayerId,
	}

	data["meta.priority"] = 200
	data["meta.kind"] = "station"
	
	return data

func deserialize(data: Dictionary):
	setLength(int(data["tileLength"]), true)
	#$Tween.seek($Tween.get_runtime())
	orbState = data["orbState"]
	keeperInsideLift = data["keeperInsideLift"]
	addedSpeedPerPlayerId = data["addedSpeedPerPlayerId"]
	
func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"lift.useorbs":
			if not newValue:
				var orbs = get_tree().get_nodes_in_group("lift_orbs")
				var res = floor(orbs.size() / 2.0)
				Data.changeByInt("inventory.iron", res)
				Data.changeByInt("inventory.water", res)
				Data.apply("lift.orbs", 0)
				for orb in orbs:
					orb.dropAllCarries(true)
					orb.queue_free()
				queuedOrbs = 0
				gravity_direction.y = -1
				gravity = 80
				setLength(tileLength, true)
			elif newValue:
				gravity = 0
		"lift.orbs":
			if not Data.of("lift.useorbs"):
				return
			
			var count = get_tree().get_nodes_in_group("lift_orbs").size()
			var diff = newValue - count - queuedOrbs
			for _i in diff:
				queuedOrbs += 1
				spawnQueuedOrb()

func getTopOfLift() -> float:
	return -40.0
		
func getBottomOfLift() -> float:
	return position.y + $Sprite2D.region_rect.size.y + 24
	
func getLength() -> float:
	return getBottomOfLift() - getTopOfLift()
	
func setLength(tileLength:int, restore:bool = false):
	if !restore and tileLength == self.tileLength:
		return
	
	var goal = GameWorld.TILE_SIZE * tileLength + 14 + GameWorld.TILE_SIZE
	var growth = goal - $Sprite2D.region_rect.size.y
	if growth <= 0 and !restore:
		return
	
	var duration = ((growth / float(GameWorld.TILE_SIZE)) if !restore else 0)
	self.tileLength = tileLength
		
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property($Sprite2D, "region_rect:size:y", $Sprite2D.region_rect.size.y, goal, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($OverlaySprite, "region_rect:size:y", $OverlaySprite.region_rect.size.y, goal, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	var pos_bonus = -20 if not Data.of("lift.useorbs") else 0
	$Tween.interpolate_property($CollisionShape2D, "position:y", $CollisionShape2D.position.y, $Sprite2D.position.y + goal*0.5 + pos_bonus, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.interpolate_property($CollisionShape2D, "shape:extents:y", $CollisionShape2D.shape.extents.y, goal*0.5 -pos_bonus, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	particles.amount = max(1, 5 * tileLength)
	$Tween.interpolate_property(particles, "process_material:emission_box_extents:y", particles.process_material.emission_box_extents.y, goal*0.5, duration, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	$build.show()
	$build/buildSfx.play()

func _physics_process(delta):
	var useOrbs = Data.of("lift.useorbs")
	for b :RigidBody2D in liftedRigids:
		if b.independent:
			# teleporter pulls it already
			continue
		var impulseX = clamp(-b.linear_velocity.x*0.15, -20.0, 20.0) + clamp(-b.position.x, -1.0, 1.0)
		var limit = 12.0 if useOrbs else 3.0
		if abs(b.position.x - position.x) > limit:
			b.apply_central_impulse(Vector2(impulseX, 0))
		
		#if tiles are not moving up in orbless we assume they are stuck
		#and give them an extra push to free them
		elif not useOrbs and b.linear_velocity.y > -1.0:
			b.apply_central_impulse(Vector2(0, -25.0))
	
	if GameWorld.softPaused():
		return
	$build.position.y = $Sprite2D.position.y + $Sprite2D.region_rect.size.y
	
func _on_Lift_body_entered(body):
	if body is RigidBody2D:
		liftedRigids.append(body)
		body.isAutoTransported = true
	elif body is Keeper:
		var ups = Data.of("lift.keeperupwardsspeed")
		if not keeperInsideLift and ups > 0:
			keeperInsideLift = true
			addedSpeedPerPlayerId[body.playerId] = ups
			Data.changeByInt(body.playerId + ".keeper.additionalupwardsspeed", ups)
	particles.emitting = liftedRigids.size()

func _on_Lift_body_exited(body):
	if body is RigidBody2D:
		liftedRigids.erase(body)
		body.isAutoTransported = false
	elif body is Keeper:
		if keeperInsideLift:
			keeperInsideLift = false
			Data.changeByInt(body.playerId + ".keeper.additionalupwardsspeed", -addedSpeedPerPlayerId[body.playerId])
			addedSpeedPerPlayerId[body.playerId] = 0

	particles.emitting = liftedRigids.size()
	
func liftUpgraded():
	particles.process_material.initial_velocity_min = max(1, Data.of("lift.speed") - 2.0)

func _on_Tween_tween_all_completed():
	$build.hide()
	$build/buildSfx.stop()

func spawnQueuedOrb():
	if queuedOrbs <=0:
		return
	
	if $Sprite2D.region_rect.size.y < GameWorld.TILE_SIZE:
		$SpawnTween.interpolate_callback(self, 1.0, "spawnQueuedOrb")
		$SpawnTween.start()
		return
		
	var l = LiftOrb.instantiate()
	add_child(l)
	if orbState.size():
		var state = orbState.pop_front()
		l.deserialize(state)
		
	if queuedOrbs > 0:
		queuedOrbs -= 1
