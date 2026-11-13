extends Drop

var dropData := []

func serialize()->Dictionary:
	var data = super.serialize()
	# 0 -> type
	# 1 -> position
	# 2 -> sprite
	# 3.. -> collision shapes
	var serializedDrops := []
	for drop in dropData:
		var sDrop := [drop[0], drop[1]]
		#sDrop.append(data[2].resource_path)
		for i in range(2, drop.size()):
			sDrop.append(var_to_str(drop[i]))
		serializedDrops.append(sDrop)
	data["serializedDrops"] = serializedDrops
	return data

func deserialize(serializedData:Dictionary):
	super.deserialize(serializedData)
	dropData.clear()
	for drop in serializedData["serializedDrops"]:
		var data := [drop[0], drop[1]]
		for i in range(2, drop.size()):
			var o = str_to_var(drop[i])
			add_child(o)
			data.append(o)
		dropData.append(data)

func addDrops(drops:Array):
	if drops.is_empty():
		return
	
	additionalSlowdown = 0.1
	mass = sqrt(drops.size()) * 0.75
	
	for drop in drops:
		if drop.absorbed:
			continue
		
		var dropPos = drop.global_position - global_position
		var data := []
		data.append(drop.type)
		data.append(dropPos)
		var s = drop.find_child("Sprite2D")
		var sCopy = s.duplicate()
		sCopy.position = dropPos
		add_child(sCopy)
		sCopy.set_meta("dropType", drop.type)
		data.append(sCopy)
		
		for c in drop.get_children():
			if c is CollisionShape2D:
				var cCopy := CollisionShape2D.new()
				cCopy.shape = c.shape.duplicate()
				cCopy.position = dropPos
				add_child(cCopy)
				data.append(cCopy)
			elif c is CollisionPolygon2D:
				var cCopy := CollisionPolygon2D.new()
				cCopy.polygon = c.polygon.duplicate()
				cCopy.position = dropPos
				add_child(cCopy)
				data.append(cCopy)
		
		dropData.append(data)
		
		for k in drop.carriedBy:
			k.dropCarry(drop)
		
		drop.dissolveCarryInfluence()
		drop.remove()
	
	var center := Vector2()
	for data in dropData:
		center += data[1]
	center /= dropData.size()
	for data in dropData:
		for i in range(2, data.size()):
			data[i].position -= center
	position += center

func pack():
	var tween := create_tween()
	tween.set_parallel(true)
	var packscale = Data.of("resourcepacker.packscale")
	for data in dropData:
		for i in range(2, data.size()):
			tween.tween_property(data[i], "position", data[i].position * packscale, 0.3).set_trans(Tween.TRANS_BOUNCE)
			if i == 2:
				tween.tween_property(data[i], "scale", data[2].scale * packscale, 0.3).set_trans(Tween.TRANS_BOUNCE)
			else:
				var c = data[i]
				if c is CollisionShape2D:
					if data[i].shape is CircleShape2D:
						tween.tween_property(data[i].shape, "radius", data[i].shape.radius * packscale, 0.3)
					elif data[i].shape is RectangleShape2D:
						tween.tween_property(data[i].shape, "size", data[i].shape.size * packscale, 0.3)
				elif c is CollisionPolygon2D:
					var points := []
					for v in c.polygon:
						points.append(v * packscale)
					c.polygon = PackedVector2Array(points)

func shred(addToInventory := true):
	if absorbed:
		return
	
	if dropTargetRef:
		dropTargetPosition = dropTargetRef.dropTarget()
		dropTargetRef = null
	
	absorbed = true
	var outDuration := 0.6
	var particle_lifetime = 0
	linear_damp = 13 #so drop won't move a lot while being shredded
	
	for data in dropData:
		if addToInventory:
			$Tween.interpolate_callback(Data, outDuration * 0.6, "changeByInt", "inventory." + data[0], 1)
		Data.changeByInt("inventory.floating" + data[0], -1)
	
	var t = create_tween()
	for c in get_children():
		if c is Sprite2D and c.material:
			t.set_parallel().tween_property(c, "modulate:a", 0, outDuration)
	
	# Adding particle_lifetime so the particles get time to finish their thing
	$Tween.interpolate_callback(self, outDuration + 0.1, "queue_free")
	$Tween.start()
	
	if is_in_group("saveable"):
		remove_from_group("saveable")

func shrink(addToInventory := true):
	if absorbed:
		return
	
	if dropTargetRef:
		dropTargetPosition = dropTargetRef.dropTarget()
		dropTargetRef = null
	
	absorbed = true
	var outDuration := 0.6
	linear_damp = 13 #so drop won't move a lot while being shredded
	
	for data in dropData:
		if addToInventory:
			$Tween.interpolate_callback(Data, outDuration * 0.6, "changeByInt", "inventory." + data[0], 1)
		Data.changeByInt("inventory.floating" + data[0], -1)
	
	$Tween.interpolate_property(self, "scale", Vector2.ONE, Vector2.ZERO, outDuration, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_property(self, "position", position, dropTargetPosition, outDuration - 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)

	$Tween.interpolate_callback(self, outDuration, "queue_free")
	$Tween.start()
	
	if is_in_group("saveable"):
		remove_from_group("saveable")
