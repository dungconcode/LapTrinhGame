extends  "res://content/map/chamber/Chamber.gd"

var id:int
var ownedCables := []
var readyToUse := false
var used := false

func _ready():
	super._ready()
	$Sprite2D.visible = false
	Data.changeByInt("map.remainingrelicswitches", 1)
	id = Data.of("map.remainingrelicswitches")
	connect_cables()
	chamberType = Data.TILE_RELIC_SWITCH

func connect_cables():
	for chamber in get_tree().get_nodes_in_group("relicchamber"):
		if chamber.type == CONST.RELIC:
			var newDestinationPos = chamber.getCenter() + chamber.global_position
			var newOriginPos = getCenter() + global_position
			var cableLine := preload("res://content/map/chamber/relicswitch/NewCable/CablePath.tscn").instantiate()
			cableLine.startPoint = newOriginPos
			cableLine.endPoint = newDestinationPos
			Level.map.bg_elements.add_child(cableLine)
			ownedCables.append(cableLine)
			chamber.connect("relic_taken", Callable(cableLine, "deactivate"))
			chamber.connect("relic_taken", Callable(self, "deactivate"))


func deserialize(data: Dictionary):
	super.deserialize(data)
	if currentState == State.OPEN or currentState == State.OPENING:
		$Sprite2D.show()
		$Sprite2D.play("opening")
		$Sprite2D.frame = $Sprite2D.sprite_frames.get_frame_count("opening")-1
		$Light3D.light_active = true
	elif currentState == State.EMPTY:
		$Sprite2D.show()
		if Data.ofOr("map.relictaken",false):
			deactivate()
		else:
			$Light3D.light_active = true
			$Sprite2D.play("running")

	# Wait until relic chambers are loaded then connect cables
	if ownedCables.size() == 0:
		await GameWorld.savegame_loaded
		connect_cables()
	
	if currentState == State.EMPTY and not Data.ofOr("map.relictaken",false):
		for cable in ownedCables:
			cable.activate()

func deactivate():
	$Sprite2D.play("deactivated")
	$Light3D.light_active = false
	$ChamberAmbOpen.queue_free()

func onExcavated():
	open()

func onOpening():
	$Tween.interpolate_callback(self, 0.4, "actuallyOpen")
	$Tween.start()

func actuallyOpen():
	$Sprite2D.play("opening")
	$DoorOpen.play()
	
	# already set it to open here so it can be activated immediately
	currentState = State.OPEN

func onRevealed():
	$Sprite2D.play("default")
	$Sprite2D.visible = true
	$ChamberAmbClosed.play()

func _on_sprite_2d_animation_looped() -> void:
	_SpriteAnimationFinishedCheck()

func _on_Sprite_animation_finished() -> void:
	_SpriteAnimationFinishedCheck()

func _SpriteAnimationFinishedCheck() -> void:
	if $Sprite2D.animation == "opening":
		readyToUse = true
		if used:
			onUsed()
	elif $Sprite2D.animation == "empty":
		$Light3D.light_active = true
		$Sprite2D.play("running")

func onUsed():
	if readyToUse:
		$Sprite2D.play("empty")
		Data.changeByInt("map.remainingrelicswitches", -1)
		$Usable.queue_free()
		$ChamberSwitchHit.play()
		$ChamberAmbClosed.stop()
		$ChamberAmbClosed.queue_free()
		$ChamberAmbOpen.play()
		currentState = State.EMPTY
		var time := 0.1
		for cable in ownedCables:
			$Tween.interpolate_callback(cable, time, "activate")
			time += 0.5
		$Tween.start()
	else:
		used = true

func addCable(cable):
	$Sprite2D.add_child(cable)
	cable.centerOffset = 11

func getTileType() -> int:
	return Data.TILE_RELIC_SWITCH
