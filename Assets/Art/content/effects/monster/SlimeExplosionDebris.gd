extends RigidBody2D

@export var styleColor: Color = Color("#208928")

var lifetime := 2.0
var maxLifetime := 2.0
var impactPos := -22.0-randf()*4.0
var lastPosition := Vector2.ZERO

@onready var monster_drip_big = $MonsterDripBig


func _ready():
	add_to_group("customStyle")
	Style.init(self)
	lifetime *= randf_range(0.5, 1.2)
	lastPosition = position
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC


var preservedLinearVelocity := Vector2.ZERO
var preservedAngularVelocity := 0.0
func pauseChanged():
	if GameWorld.paused:
		preservedLinearVelocity = linear_velocity
		preservedAngularVelocity = angular_velocity
		freeze = true
	else:
		freeze = false
		linear_velocity = preservedLinearVelocity
		angular_velocity = preservedAngularVelocity
	

func _physics_process(delta):
	if GameWorld.paused:
		return
	
	rotation = lastPosition.direction_to(position).angle()
	lastPosition = position
	
	lifetime -= delta
	monster_drip_big.frame = clamp(round(remap(lifetime, 0.0, maxLifetime, 8, 0)), 0, 8)
	
	if lifetime <= 0.0:
		queue_free()
		return
	if lifetime <= 1.5 and position.y >= impactPos:
		queue_free()

func updateStyleColor():
	modulate = Style.mapColor(styleColor)
