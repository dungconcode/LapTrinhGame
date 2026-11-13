extends RigidBody2D

@export var styleColor : Color = Color("#70aac8")
@export var maxBounces := 10

var active := true
var fadeoutStarted := false
var bounces := 0
var initialImpulse := Vector2.ZERO

func _enter_tree():
	add_to_group("customStyle")
	apply_torque(randf_range(70, 180)*sign(randf_range(-1, 1)))

func _ready():
	Style.init(self)
	Style.init($Shell)
	$Shell.play("rotate")
	apply_central_impulse(initialImpulse)

func updateStyleColor():
	modulate = Style.mapColor(styleColor).lightened(0.4)

func _on_MortarShellEmpty_body_entered(_body):
	bounces += 1
	$Shell.speed_scale = max(0.0, $Shell.speed_scale-0.15)
	if bounces > maxBounces:
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
		set_freeze_enabled.call_deferred(true)
		fadeoutStarted = true
		$FadeoutTimer.start()

func _on_RemoveTimer_timeout():
	if active and not fadeoutStarted:
		$FadeoutTimer.start()

func _on_FadeoutTimer_timeout():
	active = false
	$Tween.interpolate_property(self, "modulate:a", 1, 0, 1, Tween.TRANS_SINE, Tween.EASE_IN)
	$Tween.start()

func _on_Tween_tween_all_completed():
	queue_free()
