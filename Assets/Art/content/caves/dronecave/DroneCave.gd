extends "res://content/caves/Cave.gd"

var hasDrone := true
var opening := false

func _ready():
	super._ready()
	$Drone.visible = true
	$Door.play("default")
	$Drone.play("idle")
	
	Style.init($Drone)

func serialize()->Dictionary:
	var data = super.serialize()
	data["hasDrone"] = hasDrone
	data["opening"] = opening
	data["resourceused"] = $ResourceGrabber.spent
	return data
	
func deserialize(data: Dictionary):
	super.deserialize(data)
	hasDrone = data["hasDrone"]
	opening = data["opening"]
	$ResourceGrabber.spent = data.get("resourceused", false)
	
	if not hasDrone:
		$Drone.visible = false
		$Door.visible = false
	if opening:
		$Door.play("opening")
	
	if currentState == State.REVEALED:
		find_child("AmbSound").play()

func onRevealed():
	find_child("AmbSound").play()

func _on_door_animation_looped() -> void:
	_animationFinishedCheck()

func _on_Door_animation_finished() -> void:
	_animationFinishedCheck()

func _animationFinishedCheck() -> void:
	if $Door.animation == "opening" and hasDrone:
		$Door.visible = false
		
		$Tween.interpolate_callback(self, 2.0, "spawnDrone")
		$Tween.start()

func spawnDrone():
	var gizmo = preload("res://content/gadgets/droneyard/Squidley.tscn").instantiate()
	gizmo.position = $Drone.global_position
	$Drone.queue_free()
	Level.map.addDrop(gizmo)
	$DroneDispatcher.assignDrone(gizmo)
	hasDrone = false
	opening = false
	$Background/DroneTakenSound.play()

func _on_ResourceGrabber_grabbed_resource():
	$Door.play("opening")
	$DoorOpenSound.play()
	opening = true


