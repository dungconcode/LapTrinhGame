extends Sprite2D

var coord:Vector2
var cooldown:float
var hasMushroom := false
@onready var mushroomSprite = $mushroom

var sprites = [
	preload("res://content/gadgets/mushroomfarm/tilemyzel.png"),
	preload("res://content/gadgets/mushroomfarm/tilemyzel2.png"),
	preload("res://content/gadgets/mushroomfarm/tilemyzel3.png"),
	preload("res://content/gadgets/mushroomfarm/tilemyzel4.png"),
	]

func serialize()->Dictionary:
	var data = {
		"hasMushroom": hasMushroom,
		"coord": var_to_str(coord),
		"cooldown": cooldown,
	}
	return data
	
func deserialize(data: Dictionary):
	coord = str_to_var(data.get("coord"))
	cooldown = float(data.get("cooldown"))
	hasMushroom = data.get("hasMushroom")
	$AutoPickArea/CollisionShape2D.disabled = not hasMushroom
	if hasMushroom:
		spawnMushroom()

func _ready() -> void:
	flip_h = randf() > 0.5
	flip_v = randf() > 0.5
	Style.init(self)
	
	cooldown = randf_range(1, 2)
	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "mushroom.autopickup", true)
	
	$poof.visible = false
	$mushroom_l.visible = false
	$mushroom_d.visible = false
	$mushroom_r.visible = false
	$mushroom_t.visible = false
	
	self.texture = sprites.pick_random()
	self.flip_h = randi_range(0,1) == 0

func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"mushroom.autopickup":
			$AutoPickArea.monitoring = newValue
		"monsters.wavepresent":
			if not newValue:
				var tile = get_parent()
				if tile.health < tile.max_health:
					tile.health = min(tile.max_health, tile.health + 0.5 * tile.max_health)
					Level.map.setTileDamage(0, Vector2.ZERO, tile.position)

func _process(delta: float) -> void:
	if GameWorld.paused:
		return
	
	if not hasMushroom:
		cooldown -= delta
		if cooldown <= 0:
			spawnMushroom()

func spawnMushroom():
	var dirs = CONST.DIRECTIONS
	dirs.shuffle()
	for d in dirs:
		var neighborCoord = d + coord
		if Level.map.visibleTileCoords.has(neighborCoord) and not Level.map.tiles.has(neighborCoord):
			hasMushroom = true
			$AutoPickArea/CollisionShape2D.disabled = false
			
			if d.x < 0:
				mushroomSprite = $mushroom_l
			elif d.x > 0:
				mushroomSprite = $mushroom_r
			elif d.y < 0:
				mushroomSprite = $mushroom_t
			elif d.y > 0:
				mushroomSprite = $mushroom_d
			
			mushroomSprite.visible = true
			$Usable.position = mushroomSprite.position
			$poof.position = mushroomSprite.position + d * 6
			mushroomSprite.scale *= 0
			Style.init(mushroomSprite)
			$SpawnSound.play()

			var t = create_tween()
			t.tween_property(mushroomSprite, "scale", Vector2.ONE * 1.5, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			t.tween_property(mushroomSprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			var delay = randf_range(5,15)
			t.tween_callback(periodic_poof).set_delay(delay)
			return
	
	cooldown = 10.0 # just as a blocker that this won't run all the time in a strange case where there is no space for a new mushroom

func periodic_poof():
	if not hasMushroom:
		return
	
	var tw = create_tween()
	
	tw.tween_property(mushroomSprite, "scale", Vector2.ONE * 1.25, 1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		$poof.visible = true
		$poof.play()
		$PoofSound.play()
		
		).set_delay(0.5)
	tw.tween_property(mushroomSprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var delay = randf_range(5,15)
	tw.tween_callback(periodic_poof).set_delay(delay)
	
func canFocusUse(keeper:Keeper) -> bool:
	return hasMushroom

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func incr_buff(keeper:Keeper, bufname, bufamount:float, bufdur:float):
	var allowStack := bool(Data.of("mushroom.stack"))
	
	var buf:TemporaryBuff = keeper.getTemporaryBuff(bufname, "myzel")
	if buf:
		if allowStack:
			buf.remainingDuration += bufdur
		else:
			buf.remainingDuration = bufdur
		if buf.amount != bufamount:
			var diff = bufamount - buf.amount
			Data.changeByInt(keeper.playerId + "." + buf.property, diff)
			buf.amount = bufamount
	else:
		keeper.addTemporaryBuff(bufname, bufamount, bufdur, "myzel")

func useHit(keeper:Keeper) -> bool:
	if hasMushroom:
		$poof.play()
		$PickupSound.play()
		hasMushroom = false
		$AutoPickArea/CollisionShape2D.disabled = true
		mushroomSprite.visible = false
		
		incr_buff(keeper,"keeper.speedbuff", float(Data.of("mushroomfarm.speedbuff")), float(Data.of("mushroomfarm.speedbuffduration")))
		incr_buff(keeper,"keeper.drillbuff", float(Data.of("mushroomfarm.drillbuff")), float(Data.of("mushroomfarm.drillbuffduration")))
		
		#clear high buff and replace with stronger one
		var buf = keeper.getTemporaryBuff("keeper.highbuff", "myzel")
		var amount := 1
		if buf:
			amount += buf.amount
			buf.remainingDuration = 0.0
		keeper.addTemporaryBuff("keeper.highbuff", amount, max(Data.of("mushroomfarm.drillbuffduration"),Data.of("mushroomfarm.speedbuffduration")), "myzel")
		
		cooldown = Data.stabilizedRandomFloat(30, 50, "mushroomfarm.myzelgrowth", 40)
		
		return true
	return false

func removeFromTile():
	pass

func _on_auto_pick_area_body_entered(body: Node2D) -> void:
	if hasMushroom:
		useHit(body)
