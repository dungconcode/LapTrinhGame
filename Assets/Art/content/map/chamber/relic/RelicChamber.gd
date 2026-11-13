extends "res://content/map/chamber/Chamber.gd"

signal relic_taken

var shouldOpen := false

var stingerId:String

func _ready():
	super._ready()
	$SpriteBack.visible = false
	$SpriteBack/SpriteFront.play("closed")
	$SpriteBack.play("running")
	chamberType = Data.TILE_RELIC

func deserialize(data: Dictionary):
	super.deserialize(data)
	if currentState == State.REVEALED:
		pass
	if currentState == State.OPEN or currentState == State.OPENING or currentState == State.EMPTY:
		$Light3D.light_active = true
		$SpriteBack.show()
		$SpriteBack/SpriteFront.play("opening")
		$SpriteBack/SpriteFront.frame = $SpriteBack/SpriteFront.sprite_frames.get_frame_count("opening")-1
		
func propertyChanged(property:String, oldValue, newValue):
	match property:
		# ONLY LOWERCASE HERE
		"map.remainingrelicswitches":
			if newValue == 0:
				shouldOpen = true
				Data.unlisten(self, "map.remainingrelicswitches")

func _process(delta):
	if shouldOpen:
		for keeper in Keepers.getAll():
			if keeper.global_position.distance_to(global_position) < GameWorld.TILE_SIZE * 8:
				open()
				shouldOpen = false
				return

func onExcavated():
	if Data.of("map.remainingrelicswitches") == 0:
		open()
	else:
		# might need a state EXCAVATED
		Data.listen(self, "map.remainingrelicswitches")

func onOpening():
	$SpriteBack/SpriteFront.play("opening")
	
func onRevealed():
	$SpriteBack.visible = true
	$GizmoSpawn/ChamberAmb.play()

func onUsed():
	$DoorOpen.queue_free()
	$Usable.queue_free()
	$GizmoSpawn.queue_free()
	$Light3D.light_active = false
	$SpriteBack.play("empty")
	$GizmoSpawn/ChamberAmb.stop()

	Data.apply("map.relictaken", true)
	emit_signal("relic_taken")
	
	Achievements.triggerIfOpen("RELICHUNT_RELICTAKEN")

func _on_SpriteFront_frame_changed():
	if $SpriteBack/SpriteFront.animation == "opening":
		if $SpriteBack/SpriteFront.frame == 01:
			$DoorOpen.play()
		elif $SpriteBack/SpriteFront.frame == 50:
			$Light3D.light_active = true
			if stingerId == "":
				stingerId = "stinger_relic_chamber_excavated_" + Audio.get_closest_keeperId_or_music_override(position)
			Audio.stinger(stingerId)
		elif $SpriteBack/SpriteFront.frame == 65:
			currentState = State.OPEN

func addCable(cable):
	$SpriteBack/SpriteFront.add_child(cable)
	cable.centerOffset = 36

func getTileType() -> int:
	return Data.TILE_RELIC
