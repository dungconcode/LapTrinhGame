extends Node

var tracked_resources := {}

@onready var viewport: SubViewport = $SubViewport
@onready var effect_sprite = $"%AssessorBundleEffect"


func _ready():
	if Level.map.tilemap_size == Vector2.ONE:
		await StageManager.level_ready
	$SubViewport.size = Level.map.tilemap_size * GameWorld.TILE_SIZE
	effect_sprite.position.y = $SubViewport.size.y*0.5
	$SubViewport/Trackers.position.x = $SubViewport.size.x*0.5

class TrackedResource:
	const CarryInfluence = preload("res://content/shared/drops/CarryInfluence.gd")
	
	signal remove_tracked_resource
	
	var time_hint := 4.0
	var time_hint_divider := 1.0/time_hint
	
	var last_position := Vector2.ZERO
	var strength := 0.0
	var tracked_object : Carryable = null
	var tracked_carry_influence : CarryInfluence = null
	var tracker_sprite : Sprite2D
	
	func _init(_tracked_carry_influence:CarryInfluence, _tracker_sprite:Sprite2D):
		tracked_object = _tracked_carry_influence.getCarryable()
		tracked_carry_influence = _tracked_carry_influence
		strength = 0.0
		last_position = tracked_object.global_position
		tracked_object.connect("tree_exiting", Callable(self, "stop_tracking"))
		tracked_carry_influence.connect("tree_exiting", Callable(self, "stop_tracking"))
		tracked_carry_influence.connect("tree_exiting", Callable(self, "remove_carry_influence"))
		tracker_sprite = _tracker_sprite
	
	func update_tracker(delta:float, _offset:Vector2, viewportSize: Vector2):
		if tracked_object:
			last_position = (tracked_object.global_position - _offset)
			# in Godot 4 viewports are not v flipped, instead we need to flip positions manually
			last_position.y = viewportSize.y - tracked_object.global_position.y
			tracker_sprite.position = last_position
		
		var effect_power := 0.0
		var oscillation := 0.0
		if not tracked_carry_influence:
			strength -= delta
			effect_power = strength
		else:
			if tracked_carry_influence.beingPulled:
				effect_power = clamp(strength * time_hint, 0.0, time_hint)
			else:
				effect_power = clamp(strength, 0.0, time_hint)
				oscillation = (sin(wrapf(ease(effect_power * time_hint_divider, 0.8)*TAU*6.0, 0.0, TAU))*0.5 + 0.5) * ease((time_hint - effect_power)*time_hint_divider, 0.2)
		effect_power = effect_power * time_hint_divider
		tracker_sprite.scale = Vector2(0.5, 0.5) * (ease(effect_power, 0.1) + remap(oscillation, 0.0, 1.0, 0.0, 0.1))
		tracker_sprite.modulate.a = remap(oscillation, 0.0, 1.0, 0.0, 0.2) + ease(effect_power, 0.3)
		
		if strength <= 0.0:
			stop_tracking()
	
	func stop_tracking():
		tracked_object = null
		strength = 0.0
		emit_signal("remove_tracked_resource")
	
	func remove_carry_influence():
		tracked_carry_influence = null


func _physics_process(delta):
	var carry_influences := get_tree().get_nodes_in_group("carry_influence")
	#$Viewport/Trackers.
	for ci in carry_influences:
		if ci.carryable and not tracked_resources.has(ci.carryable):
			var new_sprite = $SubViewport/Sprite2D.duplicate()
			$SubViewport/Trackers.add_child(new_sprite)
			var tracker := TrackedResource.new(ci, new_sprite)
			tracker.connect("remove_tracked_resource", Callable(self, "_on_remove_tracked_resource").bind(tracker, ci.carryable), CONNECT_ONE_SHOT)
			tracked_resources[ci.carryable] = tracker
	
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if tracked_resources.is_empty() else SubViewport.UPDATE_ALWAYS
	# Update Tracked Resources
	for t: TrackedResource in tracked_resources.values():
		if t.tracked_carry_influence:
			var current_strength : float = t.tracked_carry_influence.strength
			if not t.tracked_object.carriedBy.is_empty():
				current_strength = 1.0
			t.strength = current_strength
		t.update_tracker(delta, Vector2.ZERO, $SubViewport.size)


func _on_remove_tracked_resource(tracker:TrackedResource, _carryable:Node):
	tracker.tracker_sprite.queue_free()
	tracked_resources.erase(_carryable)
