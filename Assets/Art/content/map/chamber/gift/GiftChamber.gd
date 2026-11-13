extends  "res://content/map/chamber/Chamber.gd"

var giftType:String

func _ready():
	super._ready()
	$Sprite2D.visible = false
	chamberType = Data.TILE_GADGET

func deserialize(data: Dictionary):
	super.deserialize(data)
	$Sprite2D.show()
	if currentState == State.OPEN or currentState == State.OPENING:
		$Sprite2D.play("opening")
		$Sprite2D.frame = $Sprite2D.sprite_frames.get_frame_count("opening") - 1
	elif currentState == State.EMPTY:
		$Sprite2D.play("empty")
	giftType = data.get("giftType", "")

func serialize()->Dictionary:
	var data = super.serialize()
	data["giftType"] = giftType
	return data

func onExcavated():
	open()
	$Sprite2D.play("opening")
	$BellSound.play()

func onRevealed():
	$Sprite2D.play("default")
	$Sprite2D.visible = true
	$BellSound.play()

func _on_Sprite_animation_finished():
	if $Sprite2D.animation == "opening":
		currentState = State.OPEN

func useHit(keeper:Keeper) -> bool:
	var r = super.useHit(keeper)
	if r:
		if giftType == "skin3":
			keeper.setSkin("skin3")
			for x in Level.loadout.keepers:
				if keeper.playerId == x.playerId:
					x.skinId = "skin3"
			GameWorld.newSkinsToUnlock.append("skin3")
		elif giftType == "pet7":
			var gizmo = preload("res://content/drop/egg/Egg.tscn").instantiate()
			gizmo.forcePetId = "pet7"
			gizmo.position = $Usable.global_position
			Level.map.addDrop(gizmo)
			keeper.attachCarry(gizmo)
	return r

func onUsed():
	$Sprite2D.play("empty")
	$Usable.queue_free()
	$BellSound.play()

func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "opening" and $Sprite2D.frame == 7:
		Audio.stinger("stinger_gadget_chamber_excavated_" + Audio.get_closest_keeperId_or_music_override(position))

func getTileType() -> int:
	return Data.TILE_GADGET
