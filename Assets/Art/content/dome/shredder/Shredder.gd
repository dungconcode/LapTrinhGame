extends Area2D

var coolDown := 0.0

var dropsArrived := []
var dropsInRange := []
var powerlevel

func getDeliverableDrop(type:String):
	var p = get_parent()
	if not p.absorbed and p.type == type:
		return p
	else:
		return null

func _process(delta):
	if coolDown > 0.0:
		coolDown -= delta
	
	if coolDown > 0.0:
		return
		
	if dropsArrived.size() == 0:
		update_power_level(0)
		return
	
	var closestDistance:float = 9999
	var closestDrop
	for drop in dropsArrived:
		if not drop.isCarried() and not drop.absorbed:
			# calculate distance, but weigh x more as the shredder has a vertical shred area
			# TODO might be different for other shredder types
			var l = getDistance(drop)
			if l < closestDistance:
				closestDistance = l
				closestDrop = drop
	if closestDrop:
		var level = 1
		if dropsInRange.size() > 20:
			level = 3
		elif dropsInRange.size() > 6:
			level = 2
		else:
			level = 1
		
		update_power_level(level)
		coolDown = 1.0/level
		shredDrop(closestDrop, level)

func update_power_level(newlevel):
	if powerlevel == newlevel:
		return
	
	match powerlevel:
		2:
			$LoopOverdrive.stop()
		3:
			$LoopUberdrive.stop()
	
	match newlevel:
		0:
			$ShredStop.play()
		2:
			$LoopOverdrive.play()
			if powerlevel < newlevel:
				$transitionOverdrive.play()
		3:
			$LoopUberdrive.play()
			if powerlevel < newlevel:
				$transitionUberdrive.play()
	
	powerlevel = newlevel
	
# overwritten by concrete shredders
func getDistance(drop) -> float:
	return (drop.global_position - $ShredPoint.global_position).length()

func shredDrop(drop,powerlevel):
	processDrop(drop)
	dropsArrived.erase(drop)
	dropsInRange.erase(drop)
	$Sprite2D.frame = 0
	$Sprite2D.play("running")
	$Sprite2D.speed_scale = powerlevel
	
	var copy = $ShredPoint/ShredSound.duplicate()
			
	copy.removeAfterPlaying = true
	add_child(copy)
	copy.play()

func processDrop(drop):
	drop.shred()

func _on_Shredder_area_entered(area):
	for r in ["iron", "water", "sand", "pack"]:
		var drop = area.getDeliverableDrop(r)
		if drop:
			drop.floatToDropTarget(self)
			if not dropsInRange.has(drop):
				dropsInRange.append(drop)
			return

func dropTarget()->Vector2:
	return $ShredPoint.global_position

func arrived(drop):
	if not dropsArrived.has(drop):
		dropsArrived.append(drop)
