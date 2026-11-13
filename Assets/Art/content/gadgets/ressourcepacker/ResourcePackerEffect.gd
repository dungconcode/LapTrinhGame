extends Area2D

var lifetime:float = 1.7

@export
var wiggle_over_lifetime: Curve
var overwritten_body_physics := []
var triggered
var carrier
var bundle
var bundleInfluence
const maxCarryDistance := 100.0

func _ready():
	$AbsorbParticles.emitting = true
	$PackingLoop.play()

func _physics_process(delta):
	if GameWorld.paused or triggered:
		return
	
	lifetime -= delta
	var innerDrops = _getRelevantBodies($InnerArea)
	if lifetime <= 0:
		if innerDrops.size() > 1:
			var isCarrying = false
			for drop in innerDrops:
				if drop.canFocusCarry() and drop.isCarried():
					isCarrying = true
			
			var pack = preload("res://content/drop/packeddrop/PackedDrop.tscn").instantiate()
			pack.position = position	
			pack.addDrops(innerDrops)
			Level.map.addDrop(pack)

			if isCarrying and (pack.global_position - carrier.global_position).length() <= maxCarryDistance:
				carrier.attachCarry(pack)
			
			if is_instance_valid(bundle) and is_instance_valid(bundleInfluence):
				bundle.addCarryable(pack, bundleInfluence.strength)

			pack.pack()
			$SuccessParticles.restart()
			triggered = true
			$PackingLoop.stop()
			$PackedSound.play()
		create_tween().tween_callback(queue_free).set_delay(2)
		return
	elif lifetime < 1.5:
		for x in innerDrops:
			#wiggle progressively stronger around
			if randf() < wiggle_over_lifetime.sample_baked(remap01clamped(lifetime,0.0,1.0)):
				x.position += Vector2(randi_range(-1,1), randi_range(-1,1))
	
	var multi = remap01clamped(lifetime, 1.2, 0.3);
	for drop in _getRelevantBodies(self):
		var diff = global_position - drop.global_position
		drop.apply_central_impulse(diff * multi)

func remap01clamped(val, istart,istop):
	return clamp(remap(val, istart, istop,0.0,1.0),0.0,1.0)

func sort_by_distance_asc(a, b):
	return (a.position - position).length() < (b.position - position).length()

func _getRelevantBodies(area:Area2D) -> Array:
	var max = Data.of("resourcepacker.packcount")
	var used :=0
	var drops := []
	for drop in area.get_overlapping_bodies():
		if drop is Drop and (drop.type == "iron" or drop.type == "water" or drop.type == "sand"):
			drops.append(drop)
			var inf = drop.getCarryInfluence()
			if inf and inf.bundle:
				bundle = inf.bundle
				bundleInfluence = inf
					
	drops.sort_custom(sort_by_distance_asc)
	
	while(drops.size() > max):
		drops.pop_back()
	
	return drops

func set_carrier(keeper:Keeper):
	carrier = keeper

func _on_inner_area_body_entered(body):
	body.linear_damp = 10
	$ResourceEnterSound.play()

func _on_inner_area_body_exited(body):
	body._updatePhysicsOverrides()
