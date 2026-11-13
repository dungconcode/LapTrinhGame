extends RefCounted

class_name CarryablePhysicsOverride

const IGNORED_VALUE:float = -9999.0

var linear_damp:float = IGNORED_VALUE
var angular_damp:float = IGNORED_VALUE
var gravity_scale:float = IGNORED_VALUE
var friction:float = IGNORED_VALUE
#var bounce:float = IGNORED_VALUE
#var owner

var creator

func _init(creator):
	self.creator = creator

func apply(body:PhysicsBody2D):
	if linear_damp != IGNORED_VALUE:
		body.linear_damp = linear_damp
	if angular_damp != IGNORED_VALUE:
		body.angular_damp = angular_damp
	if gravity_scale != IGNORED_VALUE:
		body.gravity_scale = gravity_scale
	if friction != IGNORED_VALUE:
		if body.physics_material_override:
			body.physics_material_override.friction = friction
		else:
			Logger.error("CarryablePhysicsOverride tried to set a custom friction, but body has no physics override. Not supported.", "CarryablePhysicsOverride.apply", {"body":body.name, "friction":friction})

func _to_string() -> String:
	return "linear_damp: " + str(linear_damp) + "; angular_damp: " + str(angular_damp) + "; gravity_scale: " + str(gravity_scale) + "; friction: " + str(friction)
