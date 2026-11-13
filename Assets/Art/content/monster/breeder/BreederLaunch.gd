extends Node2D


signal animation_finished

var launch_rotation := 0.0

func _ready():
	Style.init(self)

func start():
	var dir := Vector2.UP.rotated(launch_rotation) * 1300
	$Tween.interpolate_property($Sprite2D, "position", Vector2(randf_range(-20, 20), randf_range(400, 800)), dir, 5.0, Tween.TRANS_SINE, Tween.EASE_IN)
	$Tween.interpolate_property($Sprite2D, "scale", Vector2(0.1, 0.1), Vector2(1.0, 1.0), 5.0, Tween.TRANS_SINE, Tween.EASE_IN)
	var rotations = randf_range(5, 7)
	if randf() > 0.5:
		rotations *= -1
	$Tween.interpolate_property($Sprite2D, "rotation", 0, PI * rotations, 5.0)
	$Tween.start()


func pauseChanged():
	if GameWorld.paused:
		$Tween.stop_all()
		$Sprite2D.pause()
	else:
		$Tween.resume_all()
		$Sprite2D.play()


func _on_Tween_tween_all_completed():
	emit_signal("animation_finished")
	queue_free()
