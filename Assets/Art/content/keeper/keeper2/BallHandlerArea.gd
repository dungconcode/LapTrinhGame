extends Area2D

var approachingSpheres := []
var handledSpheres := []
var playerId:String

func _ready():
	set_physics_process(false)

func sphereApproaching(sphere):
	if not approachingSpheres.has(sphere):
		approachingSpheres.append(sphere)

func spherePassed(sphere):
	approachingSpheres.erase(sphere)
