extends Node2D

var cracks := []

@onready var mask_mesh: MultiMesh = $SubViewport/HitMaskMeshes.multimesh


func _ready():
	Data.listen(self, "dome.health")
	$SubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func hit(hit_position, damage):
	# The viewport has its own space, it should be aligned relative to the cracks sprite's origin
	var damagePercent:float = 100 * damage / float(Data.of("dome.maxHealth"))
	var power
	if damagePercent == 0:
		power = 0
	else:
		power = 20.0 / damagePercent
	
	if cracks.size() < mask_mesh.instance_count:
		cracks.append([0.35, power])
		var relative_position = hit_position - $Cracks.global_position
		mask_mesh.set_instance_transform_2d(cracks.size()-1, Transform2D(0.0, relative_position + Vector2(0, -500)))
		mask_mesh.set_instance_custom_data(cracks.size()-1, Color(power, 0.35, 0, 0))
		mask_mesh.visible_instance_count = cracks.size()-1
	$SubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func propertyChanged(property:String, oldValue, newValue):
	if oldValue and newValue > oldValue:
		heal(oldValue, newValue)
	
	var mh = float(Data.of("dome.maxHealth"))
	if mh > 0:
		var damage = 1 - newValue / mh
		$Cracks.material.set_shader_parameter("damage", damage)

func heal(oldValue, newValue):
	var maxHealth = Data.of("dome.maxHealth")
	# Full Heal
	if newValue == maxHealth:
		cracks.clear()
		for i in mask_mesh.instance_count:
			mask_mesh.set_instance_transform_2d(i, Transform2D(0.0, Vector2(0, 0)))
		$SubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		return
	
	var previous_health_remaining:float = maxHealth - oldValue
	var current_health_remaining:float = maxHealth - newValue
	var shrink = 1 - (current_health_remaining / previous_health_remaining)
	
	var cleared_cracks := []
	for i in cracks.size():
		cracks[i][0] *= 1 - shrink
		if cracks[i][0] <= 0.1:
			cleared_cracks.append(i)
			mask_mesh.set_instance_transform_2d(i, Transform2D(0.0, Vector2(0, 0)))
		else:
			mask_mesh.set_instance_custom_data(cracks.size()-1, Color(cracks[i][1], cracks[i][0], 0, 0))
	if cleared_cracks.size() == cracks.size():
		cracks.clear()
		cleared_cracks.clear()
	for i in cleared_cracks:
		cracks.remove_at(i)
	$SubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
