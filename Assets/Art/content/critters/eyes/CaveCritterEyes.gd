extends Node2D

const MIN_DISTANCE_FROM_KEEPER = 50
var tween: DeprecatedTween = DeprecatedTween.new()
var tile = null

func _ready():
	hide()
	add_child(tween)
	tween.interpolate_callback(self, randf_range(0, 1), "show")
	tween.start()
	
	$deathTimer.wait_time = randf_range(10, 20)
	$deathTimer.start()
	
	Style.init(self)

func _physics_process(_delta):
	for keeper in Keepers.getAll():
		var distance_to_keeper = keeper.global_position.distance_to(global_position)
		if distance_to_keeper < MIN_DISTANCE_FROM_KEEPER:
			die()

	if not is_instance_valid(tile):
		die()

func _on_deathTimer_timeout():
	die()

func die():
	queue_free()
