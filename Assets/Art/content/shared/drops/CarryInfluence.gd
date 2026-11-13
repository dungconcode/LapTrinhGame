extends Node2D

var lastStrength := 0.0
var strength := 0.0
var bundle
var cooldown := 0.0
var beingPulled := false
var totalDuration:float = 5.0 # has to be an actual number here as its not alway occuring in a bundle and its divided by this number
var carryable : Node = null

var carrier

@onready var particle_fx : GPUParticles2D = $Particles


func _ready():
	particle_fx.emitting = true
	var po = CarryablePhysicsOverride.new(self)
	po.gravity_scale = 0.0
	po.linear_damp = 0.0
	po.angular_damp = 0.0
	po.friction = 0.0
	getCarryable().addPhysicsOverride(po)

func _physics_process(delta):
	particle_fx.global_rotation = 0
	carryable = getCarryable()
	if carryable.isAutoTransported and not beingPulled and not(bundle and bundle.startedInCenter()):
		dissolve()
		return
	
	if carryable.isCarriedBy(carrier) or carryable.independent:
		exitBundle()
		strength = 0
		return
	
	if strength <= 0.0 or carryable.deactivated:
		dissolve()
		return
	
	if strength < 3.0 / totalDuration:
		particle_fx.modulate.a = ease(clamp(strength, 0.0, 1.0), 0.5)
		particle_fx.emitting = false
	else:
		particle_fx.modulate.a = clamp(strength, 0.0, 1.0)
		particle_fx.emitting = true
	
	if bundle:
		if cooldown > 0.0:
			cooldown -= delta
			return
	
	lastStrength = strength

func applyBundle(bundle):
	self.bundle = bundle
	carryable = getCarryable()
	var po = CarryablePhysicsOverride.new(bundle)
	po.gravity_scale = 0.0
	po.linear_damp = 4.0
	po.angular_damp = 1.0
	carryable.addPhysicsOverride(po)
	totalDuration = max(1.0, strength)
	#getCarryable().set_collision_layer_value(CONST.LAYER_LIFT_RIGID,false)

func isBundled() -> bool:
	return bundle != null

func getBundle():
	return bundle

func exitBundle(removeCarryInfluence := true):
	if bundle:
		#getCarryable().set_collision_layer_value(CONST.LAYER_LIFT_RIGID,true)
		carryable = getCarryable()
		carryable.removePhysicsOverride(bundle) # bundle override
		Utils.wakeUpDrop(carryable)
		bundle.removeCarryInfluence(self)
		bundle = null

func getCarryable():
	return get_parent()


func dissolve():
	exitBundle()
	carryable = getCarryable()
	carryable.remove_child(self)
	carryable.removePhysicsOverride(self)
	carryable.carryInfluence = null
	particle_fx.emitting = false
	queue_free()
