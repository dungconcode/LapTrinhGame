extends Node2D


var blockers := 1

# because mark shots can override Data, we have to mirror whatever gets passed to TeslaShot
var singleTarget
var radius
var shotType


func init():
	if singleTarget == null:
		singleTarget = Data.of("tesla.singleTarget")
	if radius == null:
		radius = Data.of("tesla.radius")
	if shotType == null:
		shotType = Data.of("tesla.shotType")
	$Lightning.visible = true
	$Lightning.connect("animation_finished", Callable(self, "decrement_blockers"))
	
	if shotType == 1: # mark
		$Lightning.play("mark")
	elif singleTarget:
		$Lightning.play("mark")
	else:
		if radius >= 60:
			$Lightning.play("nuke")
		else:
			$Lightning.play("default")
	
	
		
	Style.init(self)

func decrement_blockers():
	blockers -= 1
	if blockers <= 0:
		queue_free()

