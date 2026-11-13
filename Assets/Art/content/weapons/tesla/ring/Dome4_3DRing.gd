extends Node3D

var meshes := [
	"res://content/weapons/tesla/ring/dome4_ring_speed_0.obj",
	"res://content/weapons/tesla/ring/dome4_ring_speed_1.obj",
	"res://content/weapons/tesla/ring/dome4_ring_speed_2.obj",
	"res://content/weapons/tesla/ring/dome4_ring_speed_3.obj",
	"res://content/weapons/tesla/ring/dome4_ring_speed_4.obj"
	]

var perfectRingMeshes := [
	"res://content/weapons/tesla/ring/dome4_ring_perfect_timing_0.obj",
	"res://content/weapons/tesla/ring/dome4_ring_perfect_timing_1.obj",
	"res://content/weapons/tesla/ring/dome4_ring_perfect_timing_2.obj",
]

@export var near := 10.0
@export var far := 23.1

@export var speed := 0.0
@export var height := 0.0
@export var power := 0.0
@export var perfectTimingPower := 0.0
@export var curve : Curve
@export var flipSqueezeCurve : Curve

var isActive := false

var powerSmoothed := 0.0
var time := 0.0
var time2 := 0.0
var time3 := 0.0
var rings := {}
var flipSqueeze := 0.0
var chargeBuffer := 0.0

var targetHeight := 0.0
var targetSpeed := 0.0

var mainScene = null

@onready var ringGlowMat = $RingGroup/RingCenter/Ring0.get_surface_override_material(1)
@onready var ringPerfectTimeMat = $PerfectTimingRing/PerfectTimingRingBottom.get_surface_override_material(1)
@onready var ringCenter = $RingGroup/RingCenter

@onready var ringGroup = $RingGroup
@onready var tween = $Tween
@onready var particlePos = $RingGroup/ParticlePos

@onready var perfectTimingRing = $PerfectTimingRing
@onready var perfectTimingRingBottom = $PerfectTimingRing/PerfectTimingRingBottom
@onready var perfectTimingRingTop = $PerfectTimingRing/PerfectTimingRingTop



func _ready():
	Data.listen(self, "tesla.outerMeshId")
	Data.listen(self, "tesla.perfecttimingstage")
	$Camera3D.near = near
	$Camera3D.far = far
	for r in ringCenter.get_children():
		rings[r] = r.position

	for r in rings:
		r.mesh = load(meshes[0])
	
	ringCenter.rotation.y = TAU
	perfectTimingRingTop.rotation.z = TAU+PI/2
	perfectTimingRingBottom.rotation.z = TAU


func getRingHeight():
	return $Camera3D.unproject_position(particlePos.global_position).y


func propertyChanged(property:String, oldValue, newValue):
	match property:
		"tesla.outermeshid":
			for r in rings:
				r.mesh = load(meshes[int(newValue)])
		"tesla.perfecttimingstage":
			if newValue > 0:
				perfectTimingRing.show()
				perfectTimingRingTop.mesh = load(perfectRingMeshes[int(newValue)-1])
				perfectTimingRingBottom.mesh = load(perfectRingMeshes[int(newValue)-1])


func _process(delta):
	speed = lerp(speed, targetSpeed, delta*3.0)
	height = lerp(height, targetHeight, delta*3.0)
	time2 = wrapf(time2+delta*0.3*speed, 0, TAU)
	time3 = wrapf(time3+delta*0.5, 0, TAU)
	ringGroup.position.y = snapped((0.5 + sin(time2)*0.5)*clamp(height, 0.0, 1.0) + height*4.0 + 1.5, 0.07)
	
	var perfectTimeRingHeight = remap(height, 0.0, 1.4, 1.9, 3.1)
	perfectTimingRing.position.y = snapped((0.1 + cos(time2)*0.1)*clamp(height, 0.0, 1.0) + perfectTimeRingHeight, 0.07)
	
	if not isActive:
		time = lerp(time, TAU, delta*2)
	else:
		time = wrapf(time+delta*speed, 0, TAU)
	
	ringCenter.rotation.y = snapped(time, 0.02)
	perfectTimingRingTop.rotation.z = snapped(-time, 0.02)+PI/2
	perfectTimingRingBottom.rotation.z = snapped(time, 0.02)
	
	updatePerfectTimingRing(delta)
	
	
	if power >= powerSmoothed:
		powerSmoothed = power
		ringGlowMat.set_shader_parameter("glow_power", (power*0.2))
		if power >= 1.0:
			ringGlowMat.set_shader_parameter("glow_power", 2)
	else:
		ringGlowMat.set_shader_parameter("glow_power", power*0.2)
		powerSmoothed = lerp(powerSmoothed, power, delta*0.5)
	
	for r in rings:
		r.position = lerp(Vector3.ZERO, rings[r], ease(height, 2.2)*2.0*max(abs(1.0-powerSmoothed)-flipSqueeze, 0.0))


func updatePerfectTimingRing(delta):
	if not mainScene.perfectTimingEnabled:
		return
	if mainScene.fireValue > 0:
		chargeBuffer = mainScene.shotCharge
		var beforePerfect = mainScene.maxCharge + mainScene.perfectCooldownShotWindow.x
		var afterPerfect = mainScene.maxCharge + mainScene.perfectCooldownShotWindow.y
		var charge = max(chargeBuffer, 0.0)
		var perfectTimingPos = 1.1
		var glowPowerPerfect = 0
		if charge <= beforePerfect:
			var v = remap(min(charge, beforePerfect), 0.0, beforePerfect, 0.0, 1.0)
			perfectTimingPos = lerp(1.1, 0.35, ease(v, 30.0))
			
		elif charge >= afterPerfect:
			var v = remap(max(charge, afterPerfect), afterPerfect, 2.0, 0.0, 1.0)
			perfectTimingPos = lerp( 0.35, 1.1, ease(v, 0.1))
		else:
			glowPowerPerfect = 2.0
			perfectTimingPos = 0.35
		
		perfectTimingRingBottom.position.y = lerp(perfectTimingRingBottom.position.y, perfectTimingPos, delta*30.0)
		perfectTimingRingTop.position.y = lerp(perfectTimingRingTop.position.y, -perfectTimingPos, delta*30.0)
		ringPerfectTimeMat.set_shader_parameter("glow_power", glowPowerPerfect)
	else:
		ringPerfectTimeMat.set_shader_parameter("glow_power", 0)
		var distance = lerp(0.35, 1.1, clamp(height, 0.0, 1.0))
		perfectTimingRingBottom.position.y = lerp(perfectTimingRingBottom.position.y, distance, delta*3.0)
		perfectTimingRingTop.position.y = lerp(perfectTimingRingTop.position.y, -distance, delta*3.0)

func start():
	$DelayTimer.start()
	$EndDelayTimer.stop()

func stop():
	$DelayTimer.stop()
	$EndDelayTimer.start()

func _on_DelayTimer_timeout():
	isActive = true
	targetHeight = 1.4
	targetSpeed = 0.3

func _on_EndDelayTimer_timeout():
	isActive = false
	power = 0.0
	ringGlowMat.set_shader_parameter("glow_power", 0.0)
	targetHeight = 0
	targetSpeed = 0.0
