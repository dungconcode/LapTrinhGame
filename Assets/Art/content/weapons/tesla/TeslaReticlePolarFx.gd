extends Sprite2D

@export var polar : GradientTexture2D

var currentScale := 1.0
var particleMat : ParticleProcessMaterial = null
var remainingQuickshots := 0
var active := false

@onready var mat : Material = material
@onready var particles = find_child("Particles")
@onready var perfectTiming = find_child("PerfectTiming")
@onready var quickShotRotator = $QuickShotRotator
@onready var shotReady = find_child("Ready")

var power := 0.0


func _ready():
	mat = material.duplicate()
	material = mat
	mat.set_shader_parameter("palette", Style.palette)
	particleMat = $Particles.process_material


func _physics_process(delta):
	quickShotRotator.rotation = wrapf(quickShotRotator.rotation+delta*18.0, 0.0, TAU)


func setActive(a:bool):
	active = a
	if active:
		$Particles.emitting = true
		if remainingQuickshots > 0:
			$QuickShotRotator.show()
			$QuickshotTween.interpolate_property($QuickShotRing, "modulate:a", 0.0, 1.0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
			$QuickshotTween.start()
	else:
		$Particles.emitting = false
		$QuickshotTween.interpolate_property($QuickShotRing, "modulate:a", $QuickShotRing.modulate.a, 0.0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$QuickshotTween.start()
		$QuickShotRotator.hide()


func setPower(newPower:float):
	power = newPower
	mat.set_shader_parameter("extra_power", newPower)
	particles.modulate.a = clamp(newPower-0.7, 0.3, 1.0)
	particleMat.emission_sphere_radius = remap(newPower, 1.1, 1.8, 5, 1)


func setPerfectTiming(value:float):
	if value <= 0.0:
		perfectTiming.hide()
	else:
		perfectTiming.scale = Vector2.ONE * remap(value, 0.0, 1.0, 0.05, 1.6)
		perfectTiming.show()


func shoot():
	self_modulate.a = 0.2
	$ReleaseTween.interpolate_property(self, "self_modulate:a", 0.2, 1.0, 0.4, Tween.TRANS_EXPO, Tween.EASE_IN, 0.1)
	$ReleaseTween.start()


func setRemainingQuickshots(amount:int):
	if amount > remainingQuickshots:
		$QuickshotTween.interpolate_property($QuickShotRing, "scale", Vector2.ONE*3.0, Vector2.ONE*1.25, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$QuickshotTween.interpolate_property($QuickShotRing, "modulate:a", 0.0, 1.0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
		$QuickshotTween.start()
		$QuickShotRing.show()
		$QuickShotRotator.show()
	elif amount < remainingQuickshots:
		$QuickShotRing.hide()
		$QuickShotRotator.hide()
	remainingQuickshots = amount


func setScale(newScale:float):
	scale = Vector2.ONE*newScale
	newScale = clamp(ease(clamp(newScale, 1, 15)/15.0, 0.3)*15.0, 5.0, 15.0)
	if abs(currentScale-newScale)<0.5:
		return
	currentScale = newScale
	polar.gradient.offsets[6] = remap(newScale, 5, 15, 0.595, 0.627)
	mat.set_shader_parameter("image_add", polar)
	mat.set_shader_parameter("uv_mod", Vector2(1, remap(newScale, 5, 15, 0.0, 1.0)))
	mat.set_shader_parameter("effect_scale", remap(newScale, 5, 15, 0.2, 1.2))
	mat.set_shader_parameter("effect_repeat", remap(newScale, 5, 15, 0.2, 2.5))
	mat.set_shader_parameter("noise_scale", remap(newScale, 5, 15, 0.1, 0.02))
	mat.set_shader_parameter("noise_size", remap(newScale, 5, 15, 0.5, 3))
	mat.set_shader_parameter("pulse_intensity", remap(newScale, 5, 15, 0.05, 0.01))


func end():
	$Tween.interpolate_method(self, "setScale", scale.x, 0.01, 0.57, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_method(self, "setPower", power, 0.01, 0.57, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 0.60, "queue_free")
	$Tween.start()
