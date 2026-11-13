extends Carryable

var timeUntilNextTick:float = 2.0
var softEmitNext:bool
var idling := false
var sticks := false
var attaching := false
var killed := false
var tileToMine
var stickingTo:Vector2
var animationSuffix:String
var attachedTile
var additionalIronByTileCoord := {}

func _ready():
	super._ready()
	Style.init(self)
	contact_monitor = false
	$CageSprite.play("floating")
	$ExtractorSprite.visible = false
	self.add_to_group("pauseL")
	idling = true

func serialize()->Dictionary:
	var data = super.serialize()
	data["timeUntilNextTick"] = timeUntilNextTick
	data["idling"] = idling
	data["attaching"] = attaching
	data["sticks"] = sticks
	data["stickingTo"] = var_to_str(stickingTo)
	data["additionalIronByTileCoord"] = var_to_str(additionalIronByTileCoord)
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	timeUntilNextTick = data["timeUntilNextTick"]
	idling = data["idling"]
	attaching = data["attaching"]
	sticks = data["sticks"]
	additionalIronByTileCoord = str_to_var(data["additionalIronByTileCoord"])
	stickingTo = BackwardCompatibilityUtils.str_to_var(data["stickingTo"])
	
	if sticks:
		startAttachment()
		attachedTile = Level.map.getTile(Level.map.getTileCoord(stickingTo))
		attachedTile.connect("destroyed", Callable(self, "attachedTileDestroyed"))
	
	if sticks and stickingTo:
		changeToStatic.call_deferred()
	
func canFocusCarry() -> bool:
	return attaching or not attachedTile

func startAttachment():
	$CageSprite.visible = false
	
	$ExtractorSprite.visible = true

	$IronDetector.monitoring = false
	
	$ExtractorSprite.play("attach1")
	attaching = true
	lock_rotation = true

func stopAttachment():
	$CageSprite.visible = true
	
	$ExtractorSprite.visible = false
	$IronDetector.monitoring = true
	
	lock_rotation = false	
	attaching = false
	sticks = false
	if attachedTile:
		attachedTile.disconnect("destroyed", Callable(self, "attachedTileDestroyed"))
		attachedTile = null

func onDropped(keeper:Keeper):
	contact_monitor = true
	$CageSprite.play("floating")
	$DetectingIronSound.play()
	idling = true

func onCarried(p):
	stopAttachment()
	$DetectingIronSound.stop()

func _physics_process(delta):
	if GameWorld.paused or killed or isCarried():
		return
	
	if attaching:
		var dir := getStickToDirection()
		dir = dir.normalized()
		rotation = lerp_angle(rotation, dir.angle() - CONST.PI_HALF, delta*2)
		var goalPos = attachedTile.global_position - dir * GameWorld.TILE_SIZE * 0.65
		var dist:Vector2 = goalPos - position
		apply_central_impulse(dist.normalized())
		
		var drot = dir.angle() - rotation - CONST.PI_HALF
		if abs(drot) < 0.05 and dist.length() < 2.0:
			finishAttachement()
		return
	
	if not attachedTile:
		if $CollisionShape2D.disabled:
			# tile got destroyed while attaching
			$CollisionShape2D.disabled = false
			freeze = false
			$ExtractorSprite.offset.y = -0.5
		if not isCarried() and $IronDetector.monitoring:
			var drot = 0.0 - rotation
			apply_torque_impulse(drot * 1.5)
		
			var tiles:Array = $IronDetector.get_overlapping_bodies()
			if tiles.is_empty():
				if not idling:
					$CageSprite.play("floating")
					idling = true
			else:
				for tile in tiles:
					if tile.type == CONST.IRON:
						if idling:
							$NoticedIronSound.play()
							$DetectingIronSound.stop()
						idling = false
						$CageSprite.play("going_to_iron")
						var impulse = (tile.global_position - global_position).normalized() * 1
						apply_central_impulse(impulse)
						return
		return
	
	if not attachedTile.hasTileOverlay():
		infestWithWorms(attachedTile)
		timeUntilNextTick = Data.of("extractor.processingtime")
		return
	
	if timeUntilNextTick > 0.0:
		timeUntilNextTick -= delta * GameWorld.cycleSpeed
		return
	
	if tileToMine:
		$ExtractingSound.play()
		$ExtractorSprite.play("extract")
		if Data.of("extractor.wormanimationspeed") <= 2.0:
			tileToMine.getTileOverlay().stop()
		var addedRichness = additionalIronByTileCoord.get(tileToMine.coord, 0)
		if addedRichness > 0:
			additionalIronByTileCoord[tileToMine.coord] = addedRichness - 1
		else:
			tileToMine.richness -= 1
		#match animation time
		var type = tileToMine.type
		create_tween().tween_callback(func(): spawnDrop(type)).set_delay(0.35)
		
		if tileToMine.richness <= 0:
			Level.map.changeTileType(tileToMine, Data.TILE_DIRT_START)
		
		tileToMine.disconnect("destroyed", tileToMineDestroyed)
		tileToMine = null
		return
	
	var wormedTiles = handleSpread()
	if wormedTiles:
		wormedTiles.shuffle()
		for r in wormedTiles:
			if r.richness > 0:
				tileToMine = r
				timeUntilNextTick = Data.of("extractor.processingtime")
				#no space to emit new resources
				if $BlockedDetection.get_overlapping_bodies().size() >= 6:
					timeUntilNextTick += 0.3
					softEmitNext = true
				tileToMine.getTileOverlay().play()
				tileToMine.connect("destroyed", tileToMineDestroyed)
				return 
		
		kill()
	else:
		timeUntilNextTick = Data.of("extractor.processingtime") * 0.5
		return
	
	# nothing left to mine
	kill()

func infestWithWorms(tile):
	tile.setTileOverlay(Data.TILE_OVERLAY_WORMS)
	#after loading a save tiles will get reinfested, but we don't want them to receive additional resources
	if not additionalIronByTileCoord.has(tile.coord):
		additionalIronByTileCoord[tile.coord] = Data.of("extractor.additionalresources")

func spawnDrop(type):
	var drop = Data.DROP_SCENES.get(type).instantiate()	
	var dir = getStickToDirection().normalized().rotated(PI)
	drop.position = position + dir * 10
	if softEmitNext:
		softEmitNext = false
	else:
		drop.apply_central_impulse(dir.rotated(randf_range(-0.4, 0.4)) * randf_range(30, 60))
	$DrillHitParticles.restart()
	Level.map.call_deferred("addDrop", drop)
	GameWorld.incrementRunStat("resources_mined")
	
func tileToMineDestroyed():
	tileToMine = null

func handleSpread():
	var wormedTiles := [attachedTile]
	var i := 0
	while true:
		if i >= wormedTiles.size() or i > 1000:
			break
		
		var tile = wormedTiles[i]
		i += 1
		
		CONST.DIRECTIONS.shuffle()
		for d in CONST.DIRECTIONS:
			var otherCoord:Vector2 = tile.coord + d
			var otherTile = Level.map.getTile(otherCoord)
			var res = Level.map.getTileData().get_resourcev(otherCoord)
			
			if otherTile:
				if otherTile.isTileOverlayType(Data.TILE_OVERLAY_WORMS):
					if not wormedTiles.has(otherTile):
						wormedTiles.append(otherTile)
				elif res == Data.TILE_IRON and not otherTile.hasTileOverlay():
					infestWithWorms(otherTile)
					return null
			else:
				if res == Data.TILE_IRON:
					Level.map.revealTile(otherCoord)
					var t = Level.map.getTile(otherCoord)
					if not t.hasTileOverlay():
						infestWithWorms(t)
					return null
	return wormedTiles

func getWormedTiles():
	var wormedTiles := [attachedTile]
	var i := 0
	$ExtractingSound.play()
	while true:
		if i >= wormedTiles.size() or i > 1000:
			break
		
		var tile = wormedTiles[i]
		i += 1
		
		CONST.DIRECTIONS.shuffle()
		for d in CONST.DIRECTIONS:
			var otherCoord:Vector2 = tile.coord + d
			var otherTile = Level.map.getTile(otherCoord)
			var res = Level.map.getTileData().get_resourcev(otherCoord)
			
			if otherTile:
				if otherTile.isTileOverlayType(Data.TILE_OVERLAY_WORMS):
					if not wormedTiles.has(otherTile):
						wormedTiles.append(otherTile)
				elif res == Data.TILE_IRON and not otherTile.hasTileOverlay():
					infestWithWorms(otherTile)
					return
			else:
				if res == Data.TILE_IRON:
					Level.map.revealTile(otherCoord)
					var t = Level.map.getTile(otherCoord)
					if not t.hasTileOverlay():
						infestWithWorms(t)
					return

func kill():
	killed = true
	var wormedTiles := [attachedTile]
	var i := 0
	while i < wormedTiles.size():
		var tile = wormedTiles[i]
		i += 1
		for d in CONST.DIRECTIONS:
			var otherCoord:Vector2 = tile.coord + d
			var otherTile = Level.map.getTile(otherCoord)
			if otherTile:
				if otherTile.isTileOverlayType(Data.TILE_OVERLAY_WORMS):
					if not wormedTiles.has(otherTile):
						wormedTiles.append(otherTile)
	if Data.of("extractor.destroyonfinish"):
		var tween := DeprecatedTween.new()
		Level.map.add_child(tween)
		$DetatchSound.play()
		var delay = 0.5
		for tile in wormedTiles:
			tween.interpolate_callback(tile, delay, "hit", Vector2.ZERO, tile.max_health)
			CONST.DIRECTIONS.shuffle()
			for d in CONST.DIRECTIONS:
				delay += randf_range(0.03, 0.1)
				tween.interpolate_callback(self, delay, "destroyTile", tile.coord + d)
			delay += randf_range(0.1, 0.2)
		tween.interpolate_callback(tween, delay + 0.1, "queue_free")
		$ExtractingSound.stop()
		tween.start()
	else:
		for tile in wormedTiles:
			tile.removeTileOverlay()
	
	$ExtractorSprite.play("vanish")
	$ExtractingSound.stop()

func destroyTile(coord):
	var otherTile = Level.map.getTile(coord)
	if otherTile and not otherTile.isTileOverlayType(Data.TILE_OVERLAY_WORMS)\
	 and not otherTile.exploded and Data.isDestructable(otherTile):
		otherTile.exploded = true
		otherTile.hit(Vector2.ZERO, otherTile.max_health)

func getStickToDirection() -> Vector2:
	var delta = stickingTo - global_position
	if abs(delta.x) > abs(delta.y):
		delta.y = 0
	else:
		delta.x = 0
	return delta

func _on_Mine_body_entered(body):
	if not body.has_meta("destructable") or not body.get_meta("destructable"):
		return
	
	if body.type != CONST.IRON:
		return
	
	if not attachedTile:
		startAttachment()
		sticks = true
		stickingTo = body.global_position
		attachedTile = body
		attachedTile.connect("destroyed", Callable(self, "attachedTileDestroyed"))

func finishAttachement():
	if not $CollisionShape2D.disabled:
		$StartAttachSound.play()
		changeToStatic.call_deferred()
		$CollisionShape2D.disabled = true
		$ExtractorSprite.play("attach2")
		$ExtractorSprite.offset.y = -2.5

func attachedTileDestroyed():
	if attaching:
		stopAttachment()
	else:
		kill()
	attachedTile = null

func changeToStatic() -> void:
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true

func _on_sprite_animation_finished() -> void:
	match $CageSprite.animation:
		"floating":
			if randf() > 0.8:
				$CageSprite.play("come_out")
			else:
				$CageSprite.play("floating")
		"come_out":
			$CageSprite.play("idle")
		"idle":
			if randf() > 0.7:
				$CageSprite.play("hide")
			else:
				$CageSprite.play("idle")
		"hide":
			$CageSprite.play("floating")

func _on_extractor_sprite_animation_finished() -> void:
	match $ExtractorSprite.animation:
		"attach2":
			if not attachedTile or not is_instance_valid(attachedTile):
				pass
			$ActivateSound.play()
			attaching = false
			$ExtractorSprite.play("extract_idle")
		"extract":
			$ExtractorSprite.play("extract_idle")
		"vanish":
			queue_free()

func pauseChanged():
	#disable movement when not frozen in pause mode
	if not sticks or not stickingTo:
		super.pauseChanged()
