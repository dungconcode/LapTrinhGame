extends Node2D

var start := Vector2.ZERO
var target := Vector2.ZERO

@onready var speed := 1.0
@onready var arcGroupFollow = $ArcGroupFollow

func _ready():
	$Tween.interpolate_method(self, "changeTarget", start, target, (start.distance_to(target)/2500.0)*speed)
	$Tween.start()

func changeTarget(new:Vector2):
	arcGroupFollow.global_position = new

func _on_Tween_tween_all_completed():
	queue_free()
