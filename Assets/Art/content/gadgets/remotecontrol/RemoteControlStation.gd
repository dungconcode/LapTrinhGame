extends Node2D

var speed := 0.0
var minY := 0.0
var maxY := 0.0
var revealCooldown := 0.0
var isOpen := false
var keeperInStation:Keeper
var keeperId:String
var controlledWeapons:Array
var virtualCameraTarget
var screenEffect
var tw
var inputProcessor = null

var inRapidAscent := false
var rapidAscentStartPos:float

func _ready() -> void:
	Style.init(self)
	$KeeperSprite.visible = false
	virtualCameraTarget = preload("res://content/gadgets/remotecontrol/VirtualCameraTarget.tscn").instantiate() 
	Level.map.add_child(virtualCameraTarget)
	


func _physics_process(delta: float) -> void:
	if GameWorld.paused or inRapidAscent:
		return
	
	var prev_speed = speed
	var keeper = Keepers.getClosestKeeper(global_position)
	if keeper:
		var diff = keeper.position.y - global_position.y
		var goalSpeed = clamp(diff * 0.5, -50, 50)
		speed = clamp(speed + (goalSpeed - speed) * delta * 25, -50, 50)
		
		var dist = global_position - keeper.position
		var coord = Level.map.getTileCoord(global_position)
		var blocked = Level.map.getTile(coord) != null
		
		if isOpen:
			if dist.length() > 100 or blocked:
				close()
		else:
			if dist.length() < 60 and not blocked:
				open()
	else:
		speed = lerp(speed, 0.0, delta * 5)
		
		
	position.y += speed * delta
	
	#breaking particles
	if abs(prev_speed) > abs(speed) and abs(speed) > 1.0:
		$MoveParticlesDown.amount_ratio = clamp(-speed/50.0,0,1)
		$MoveParticlesUp.amount_ratio = clamp(speed/50.0,0,1)
	else:
		$MoveParticlesDown.amount_ratio = 0
		$MoveParticlesUp.amount_ratio = 0
		
	var moveSound = abs(speed) > 1.0
	$StationMoveSound.additionalVolume = min(0, -10 + abs(speed))
	if moveSound != $StationMoveSound.playing:
		if moveSound:
			$StationMoveSound.play()
		else:
			$StationMoveSound.stop()
			
	
	if position.y < minY:
		position.y = minY
		speed = 0

	if position.y > maxY:
		position.y = maxY
		speed = 0
	
	if revealCooldown > 0.0:
		revealCooldown -= delta
	else:
		revealCooldown = 1.0
		var radius = Data.of("stationextension.tilerevealdistance")
		var center = Level.map.getTileCoord(position)
		var t = create_tween()
		t.set_parallel(true)
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var dir = Vector2(x, y)
				if dir.length() > radius:
					continue
				
				var coord = center + Vector2i(x, y)
				if not Level.map.isRevealed(coord):
					var delay = dir.length() * randf_range(0.15, 0.25)
					t.tween_callback(reveal.bind(coord)).set_delay(delay)

func reveal(coord):
	Level.map.tileCoordsToReveal.append(coord)
	Level.map.floodRevealTiles()
	Level.map.revealTileVisually(coord)

func close():
	$Sprite.play("close")
	$CloseDoorSound.play()
	isOpen = false

func open():
	$Sprite.play("open")
	$OpenDoorSound.play()
	isOpen = true


func canFocusUse(keeper:Keeper) -> bool:
	return isOpen

#only interactable with useHit, to avoid issues when carrying resources as assessor
func useHold(keeper:Keeper) -> bool:
	return false

func useHit(keeper:Keeper) -> bool:
	if keeperInStation or not keeper.canEnterRemoteStation():
		return false
	
	keeperId = keeper.techId
	keeper.enterStation(false)
	$EnterStationSound.play()
	keeperInStation = keeper
	
	var i = preload("res://content/gadgets/remotecontrol/RemoteStationInputProcessor.gd").new()
	i.popup = preload("res://content/gadgets/remotecontrol/RemoteStationPopup.tscn").instantiate()
	i.deviceId = Keepers.getDeviceId(keeper.playerId)
	i.keeper = keeper
	i.station = self
	i.integrate(self)
	inputProcessor = i
	Level.stage.showPopup(i.popup)
	
	$Sprite.play("activate")
	$KeeperSprite.sprite_frames = keeperInStation.get_node("Sprite2D").sprite_frames
	$KeeperSprite.visible = true
	
	return true

func transitionToDome(keeper):
	if not screenEffect:
		screenEffect = preload("res://content/gadgets/remotecontrol/RemoteStationScreenEffects.tscn").instantiate()
		Level.stage.showPopup(screenEffect)
	
	keeper.virtuallyIsInsideDome = true
	
	screenEffect.set_effects_active(false)
	screenEffect.set_visible(true)
	screenEffect.fade_out()
	
	if tw:
		tw.kill()
	
	tw = create_tween()
	tw.tween_callback(func():
		screenEffect.set_effects_active(true)
		screenEffect.fade_in()
		$ActivateSound.play()
		Level.stage.getVignette().modulateOnPlayerY = false
		setCamOnDome()
	).set_delay(1)


func setCamOnDome():
	var cam = InputSystem.getCamera()
	if cam:
		cam.target = virtualCameraTarget
		cam.jump()
		override_palette()

func setCamOnKeeper():
	var cam = InputSystem.getCamera()
	if cam:
		cam.target = keeperInStation
		keeperInStation.virtuallyIsInsideDome = false
		keeperInStation.isInsideDome = false
		cam.jump()
		Style.setPalette(Style.paletteId) #reset palette
		Level.stage.getVignette().modulateOnPlayerY = true

func grayscale_col(col:Color):
	var v := Vector3(col.r, col.g, col.b)
	var g = v.dot(Vector3(0.2126, 0.7152, 0.0722))
	return Color(g,g,g,col.a)

func override_palette():
	var image = load(Style.getPalettePath(Style.paletteId)).get_image()
	
	#grayscale
	var w = image.get_width()/10
	var h = image.get_height()/10 -2 #do not affect UI colors
	for y in h:
		if  y != 3 and y != 5 and y != 9: #do not change colors of outside dome gadgets, monsters and resources
			for x in w:
				image.fill_rect(Rect2i(x*10,y*10,10,10), grayscale_col(image.get_pixel(x*10, y*10)))
	
	#swap primary moster color with secondary, make rest white
	image.fill_rect(Rect2i(0,90,10,10), image.get_pixel(15, 95))
	image.fill_rect(Rect2i(10,90,310,10),Color.WHITE_SMOKE)
	
	Style.setPaletteToImg(ImageTexture.create_from_image(image))

func _on_sprite_animation_finished() -> void:
	if $Sprite.animation == "activate":
		$Sprite.play("running")

func getKeeperPosition() -> Vector2:
	return $Usable.global_position

func exitStation():
	$KeeperSprite.visible = false
	
	if screenEffect:
		closeScreenEffect()
		var tw = create_tween()
		tw.tween_callback(func():
			keeperInStation = null
			$Sprite.play("deactivate")
		).set_delay(1.5)
	else:
		setCamOnKeeper()
		$ExitStationSound.play()
		keeperInStation = null
		$Sprite.play("deactivate")

func closeScreenEffect():
	if not screenEffect:
		return
	
	if tw:
		tw.kill()
	
	screenEffect.set_effects_active(true)
	screenEffect.set_visible(true)
	screenEffect.fade_out()
	tw = create_tween()
	tw.tween_callback(func():
		if screenEffect:
			screenEffect.set_effects_active(false)
			screenEffect.fade_in()
		setCamOnKeeper()
		$ExitStationSound.play()
	).set_delay(1)
	tw.tween_callback(func():
		if screenEffect:
			screenEffect.queue_free()
			screenEffect = null
	).set_delay(0.5)
	
func rapidAscentProcess(v):
	position = Vector2(position.x, lerp(rapidAscentStartPos, minY, v))
	keeperInStation.global_position = global_position
	$MoveParticlesDown.amount_ratio = v * 10.0
	InputSystem.getCamera().jump()

func startRapidAscent():
	rapidAscentStartPos = position.y
	inRapidAscent = true
	Level.stage.unpause()
	
	var duration = 3.0 #abs(minY - rapidAscentStartPos) /150.0
	InputSystem.getCamera().shake(200.0, duration)
	
	var tw = create_tween()
	tw.tween_method(rapidAscentProcess, 0.0,1.0, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
	
	tw.tween_callback(func():
		inRapidAscent = false
		inputProcessor.desintegrate()
		)
	
	pass

func getDome():
	return Level.dome

func getControlledWeapons() -> Array:
	return Level.dome.getWeapons()

func serialize()->Dictionary:
	var data = {
		"position" = var_to_str(global_position),
		"speed" = speed,
		"is_open" = isOpen,
	}
	return data

func deserialize(data:Dictionary):
	global_position = BackwardCompatibilityUtils.str_to_var(data["position"])
	speed = data["speed"]
	if data["is_open"]:
		open()
	else:
		close()
