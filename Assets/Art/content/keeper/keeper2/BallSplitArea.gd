extends "res://content/keeper/keeper2/BallHandlerArea.gd"

var catching := false

func start(playerId):
	self.playerId = playerId
	Data.listen(self, playerId + ".keeper2.spheresplit", true)
	$AnimatedSprite2D.visible = false

func propertyChanged(property:String, oldValue, newValue):
	if not is_physics_processing() and newValue:
		visible = true
		Level.addTutorial(self, "assessor2_split")
		$BallCatchCollision.disabled = false
		set_physics_process(newValue)

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	if catching:
		for sphere in get_overlapping_bodies():
			if not handledSpheres.has(sphere) and sphere.size > 0.3:
				if sphere.generation >= 4:
					Achievements.triggerIfOpen("KEEPER2_SPLITS")
				sphere.catch()
				var newSize = sphere.size * Data.of(playerId + ".keeper2.splitlifetime")

				var keeper = get_parent()
				var keeperCoord = Level.map.getTileCoord(keeper.global_position)
				var newPos = Level.map.getTilePos(keeperCoord)
				
				var slice = preload("res://content/keeper/keeper2/SplitSlice.tscn").instantiate()
				slice.global_position = sphere.global_position
				slice.global_rotation = sphere.linear_velocity.angle()
				keeper.get_parent().add_child(slice)
				
				var sphere1 = preload("res://content/keeper/keeper2/Pinball.tscn").instantiate()
				sphere1.playerId = playerId
				sphere1.size = newSize
				sphere1.generation = sphere.generation + 1
				sphere1.position = newPos + Vector2.ONE * GameWorld.TILE_SIZE * randf_range(-0.2, 0.2)
				keeper.get_parent().add_child(sphere1)
				sphere1.apply_central_impulse(100 * sphere.linear_velocity.rotated(CONST.PI_HALF).normalized())
				sphere1.lifeTime *= newSize
				sphere1.modulate.b = 0.6
				
				var sphere2 = preload("res://content/keeper/keeper2/Pinball.tscn").instantiate()
				sphere2.playerId = playerId
				sphere2.size = newSize
				sphere2.generation = sphere.generation + 1
				sphere2.position = newPos + Vector2.ONE * GameWorld.TILE_SIZE * randf_range(-0.2, 0.2)
				keeper.get_parent().add_child(sphere2)
				sphere2.apply_central_impulse(100 * sphere.linear_velocity.rotated(-CONST.PI_HALF).normalized())
				sphere2.lifeTime *= newSize
				sphere2.modulate.b = 0.6
				
				handledSpheres.append(sphere)
				handledSpheres.append(sphere1)
				handledSpheres.append(sphere2)
				
				keeper.ballActionCooldown = Data.of(playerId + ".keeper2.actioncooldown")
				InputSystem.shakeTarget(self, 100, 0.2)
	
	if catching:
		$AnimatedSprite2D.play("reflect")
	elif get_parent().ballActionCooldown > 0.0:
		$AnimatedSprite2D.play("active")
	elif $AnimatedSprite2D.visible:
		$AnimatedSprite2D.visible = false
		$SplitReady.play()
	
	$AnimatedSprite2D.rotation = randf() * TAU

func catch():
	catching = true
	$AnimatedSprite2D.visible = true
	$SplitActivated.play()

func stopCatching():
	catching = false
	handledSpheres.clear()
