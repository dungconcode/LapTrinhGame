extends Node2D

func _ready():
	$Hit.play()

func _on_Hit_finished():
	queue_free()
