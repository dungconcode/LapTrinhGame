extends RigidBody2D

var rot := 0.0
var speed := 1.0
var active := false

@onready var particles = $GPUParticles2D

func _ready():
	Style.init(self)
	apply_central_impulse(Vector2.UP.rotated(randf_range(-0.9, 0.9))*randf_range(80, 240)*speed)

var preservedLinearVelocity := Vector2.ZERO
var preservedAngularVelocity := 0.0
func pauseChanged():
	if GameWorld.paused:
		preservedLinearVelocity = linear_velocity
		preservedAngularVelocity = angular_velocity
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
		freeze = true
	else:
		freeze = false
		linear_velocity = preservedLinearVelocity
		angular_velocity = preservedAngularVelocity

func _process(delta):
	if GameWorld.paused:
		return
	rot = wrapf(rot+delta*10, 0, TAU)
	particles.position = Vector2(2, 0).rotated(rot)


func _on_SmoketrailDebris_body_entered(_body):
	if not active:
		return
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	set_freeze_enabled.call_deferred(true)
	$TimerStart.wait_time = randf_range(0.3, 0.6)
	$TimerStart.start()


func _on_Timer_timeout():
	queue_free()


func _on_TimerStart_timeout():
	if not active:
		active = true
	else:
		$GPUParticles2D.emitting = false
		$Timer.wait_time = 1.3
		$Timer.start()
