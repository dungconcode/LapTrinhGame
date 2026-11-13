extends  "res://content/map/chamber/Chamber.gd"

func _ready():
	super._ready()
	$Sprite2D.visible = false
	$SocketedGizmo.visible = false
	chamberType = Data.TILE_GADGET
	$ResourceGrabber.disable()
	$Resource.visible = false

func serialize() -> Dictionary:
	var data:Dictionary = super.serialize()
	data["spent"] = $ResourceGrabber.spent
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	$ResourceGrabber.spent = data["spent"]
	
	$Sprite2D.show()
	if currentState == State.OPEN or currentState == State.OPENING:
		$Sprite2D.play("opening")
		$Sprite2D.frame = $Sprite2D.sprite_frames.get_frame_count("opening")-1
		$SocketedGizmo.show()
	elif currentState == State.EMPTY:
		$Sprite2D.play("empty")
		$SocketedGizmo.hide()
	elif $ResourceGrabber.spent:
		_on_ResourceGrabber_grabbed_resource()

func onExcavated():
	_on_Timer_timeout()
	$ResourceGrabber.enable()

func onRevealed():
	$Sprite2D.play("default")
	$Sprite2D.visible = true

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
		Audio.stinger("stinger_gadget_chamber_excavated_" + Audio.get_closest_keeperId_or_music_override(position))

func _on_ResourceGrabber_grabbed_resource():
	open()
	$DoorOpen.play()
	$Sprite2D.play("opening")
	$Timer.queue_free()
	$WaterShineSprite.queue_free()
	$Resource.visible = true

func _on_Timer_timeout():
	$WaterShineSprite.play()
	$WaterShineSprite.frame = 0
	$Timer.wait_time = randf_range(2.0, 3.5)
	$Timer.start()

func getTileType() -> int:
	return Data.TILE_SUPPLEMENT
