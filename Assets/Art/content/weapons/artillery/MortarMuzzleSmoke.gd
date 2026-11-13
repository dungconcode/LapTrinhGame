extends Node2D

func _ready():
	Style.init($MuzzleSmoke)
	Style.init($MuzzleSmoke2)
	$MuzzleSmoke.restart()
	$MuzzleSmoke2.restart()


func _on_Timer_timeout():
	queue_free()
