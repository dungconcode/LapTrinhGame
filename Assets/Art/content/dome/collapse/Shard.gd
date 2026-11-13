extends RigidBody2D

func _ready():
	Style.init(self)
	
	# Choose a random frame from the sprite sheet
	var n = randi() % $Sprite2D.hframes
	$Sprite2D.frame = n
	
	# Apply a random explosion impulse in a 180 degree arc upwards
	apply_central_impulse(Vector2(randf() * 100, 0).rotated(randf() * -PI))
