extends Node2D


@export var windupVolumeCurve : Curve
@export var windupVolumeMax := -13.0
@export var windupVolumeMin := -24.0
@export var windupPitchCurve : Curve
@export var windupPitchMax := 1.1
@export var windupPitchMin := 0.6

@export var ringVolumeCurve : Curve
@export var ringVolumeMax := -8
@export var ringVolumeMin := -24.0
@export var ringPitchCurve : Curve
@export var ringPitchMax := 1.1
@export var ringPitchMin := 0.6

@export var revVolDb := -4.0

var shotCharge := 0.0
var shotChargeBuffer := 0.0
var dbMulti := 0.0
var pitchMulti := 0.0
var dbStartStop := -12.0

func _ready():
	$WindupLoop.play()
	$RingLoop.play()

func start():
	dbStartStop = 0.0

func stop():
	dbStartStop = -12.0


var pressing := false
func _physics_process(delta):
	if shotCharge > shotChargeBuffer or shotCharge >= 1.0:
		if not pressing:
			pressing = true
			$Rev.play(shotCharge * $Rev.stream.get_length())
			$perfectCount.play(shotCharge * $perfectCount.stream.get_length()*0.666)
		dbMulti = lerp(dbMulti, 0.0, delta*8.0)
		pitchMulti = lerp(pitchMulti, 0.0, delta*8.0)
	else:
		pressing = false
		$Rev.stop()
		$perfectCount.stop()
		dbMulti = lerp(dbMulti, -14.0, delta*10.0)
		pitchMulti = lerp(pitchMulti, -0.3, delta*8.0)
	shotChargeBuffer = shotCharge
	
	$Rev.volume_db = revVolDb + dbMulti
	
	var chargeValue = ($"%FGScene".speed*delta)*10.0
	
	$WindupLoop.volume_db = remap(windupVolumeCurve.sample(chargeValue), 0, 1, windupVolumeMin, windupVolumeMax) + dbMulti + dbStartStop
	$RingLoop.volume_db = remap(ringVolumeCurve.sample(chargeValue), 0, 1, ringVolumeMin, ringVolumeMax) + dbMulti + dbStartStop
	$WindupLoop.pitch_scale = remap(windupPitchCurve.sample(chargeValue), 0, 1, windupPitchMin, windupPitchMax) + pitchMulti
	$RingLoop.pitch_scale = remap(ringPitchCurve.sample(chargeValue), 0, 1, ringPitchMin, ringPitchMax) + pitchMulti
	
