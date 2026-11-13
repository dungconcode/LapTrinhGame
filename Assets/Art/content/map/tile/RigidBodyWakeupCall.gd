extends Area2D


func _ready() -> void:
	var t := get_tree()
	await t.physics_frame
	await t.physics_frame
	for r in get_overlapping_bodies():
		Utils.wakeUpDrop(r)
	queue_free()
