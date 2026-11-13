extends  "res://content/map/chamber/Chamber.gd"

var stingerId:String

func _ready():
	super._ready()
	$Sprite2D.visible = false
	$SocketedGizmo.visible = false
	chamberType = Data.TILE_GADGET

func deserialize(data: Dictionary):
	super.deserialize(data)
	$Sprite2D.show()
	if currentState == State.OPEN or currentState == State.OPENING:
		$Sprite2D.play("opening")
		$Sprite2D.frame = $Sprite2D.sprite_frames.get_frame_count("opening")-1
		$SocketedGizmo.show()
	elif currentState == State.EMPTY:
		$Sprite2D.play("empty")
		$SocketedGizmo.hide()

func onExcavated():
	open()
	$Sprite2D.play("opening")
	$DoorOpen.play()

func onRevealed():
	$Sprite2D.play("default")
	$Sprite2D.visible = true

func useHit(keeper:Keeper) -> bool:
	return super.useHit(keeper)

func _on_Sprite_animation_finished():
	if $Sprite2D.animation == "opening":
		currentState = State.OPEN
		$SocketedGizmo.visible = true

func onUsed():
	$Sprite2D.play("empty")
	$SocketedGizmo.queue_free()
	$Usable.queue_free()
	$GizmoSpawn/ChamberAmb.queue_free()
	$DoorOpen.queue_free()
	$GizmoSpawn.queue_free()
	
func _on_Sprite_frame_changed():
	if $Sprite2D.animation == "opening" and $Sprite2D.frame == 7:
			if stingerId == "":
				stingerId = "stinger_gadget_chamber_excavated_" + Audio.get_closest_keeperId_or_music_override(position)
			Audio.stinger(stingerId)

func getTileType() -> int:
	return Data.TILE_GADGET
