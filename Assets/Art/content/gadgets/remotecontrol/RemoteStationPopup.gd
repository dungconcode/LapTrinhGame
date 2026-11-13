extends Control

var isIn := false
var outLeft := false
var outRight := false
var playerCoord:Vector2

# engine bug? Starting new tweening in the frame the old interpolation stops does not work.
var tween2:DeprecatedTween

func _ready():
	Style.init(self)
	position.y += size.y
	
	if Data.of("stationextension.showminimap"):
		setupMinimap()
	else:
		$MiniMap.visible = false
	
	tween2 = DeprecatedTween.new()
	add_child(tween2)
	
	setAllowUpgrades(Data.of("stationextension.buyupgrades"))
	setAllowEmergencyExit(Data.of("stationextension.movetube"))
	
	$PanelContainer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM,Control.PRESET_MODE_MINSIZE)

func setupMinimap():
	$MiniMap.visible = true
	%MapData.clear()
	var td:MapData = Level.map.getTileData()
	
	var visibility = {}
	for x in Level.map.visibleTileCoords:
		visibility[x] = 0
	
	#grow visibility out
	for p in Data.ofOr("stationextension.minimapdepth", 0):
		for x in visibility:
			if visibility[x] == p:
				for offset in CONST.DIRECTIONS:
					var idx = x + offset
					if not visibility.has(idx):
						visibility[idx] = p + 1
	
	for cell in visibility:
		var biome = td.get_biomev(cell)
		if biome < 0:
			continue
		var res = td.get_resourcev(cell)
		if res != -1:
			%MapData.set_resourcev(cell, res)
		else:
			%MapData.set_resourcev(cell, 20)
	
	var rect:Rect2i = %MapData.get_used_rect()
	
	#mark player on map
	for x in Keepers.getAll():
		playerCoord = Level.map.getTileCoord(x.global_position)
		%MapData.set_resourcev(playerCoord, 3)
		create_tween().tween_callback(flipPlayerCoord).set_delay(0.3)
	
	for drop in get_tree().get_nodes_in_group("drops"):
		var coord = Level.map.getTileCoord(drop.global_position)
		#out-of-bounds drops can brake the visualization
		if not rect.has_point(coord):
			continue
		
		var type:int
		var layer:int
		match drop.type:
			CONST.IRON: 
				type = 15
				layer = 3
			CONST.WATER: 
				type = 16
				layer = 4
			CONST.SAND: 
				type = 17
				layer = 5
		%MapData.set_cell(layer, coord, 0, Vector2i(type % 10, type / 10))
		
	for carryable in get_tree().get_nodes_in_group("carryable"):
		if carryable.carryableType == "resource":
			continue
		var coord = Level.map.getTileCoord(carryable.global_position)
		#out-of-bounds drops can brake the visualization
		if not rect.has_point(coord):
			continue
		%MapData.set_cell(6, coord, 0, Vector2i(8, 1))
	
	for drop in get_tree().get_nodes_in_group("drops"):
		var coord = Level.map.getTileCoord(drop.global_position)
		#out-of-bounds drops can brake the visualization
		if not rect.has_point(coord):
			continue
		var type:int
		var layer:int
		match drop.type:
			CONST.IRON: 
				type = 15
				layer = 3
			CONST.WATER: 
				type = 16
				layer = 4
			CONST.SAND: 
				type = 17
				layer = 5
			_: 
				type = 18
				layer = 6
		%MapData.set_cell(layer, coord, 0, Vector2i(type % 10, type / 10))
	
	#adjust position and size
	
	const MIN_SIZE := 40
	if rect.size.y > 0:
		if rect.size.x <MIN_SIZE or rect.size.y < MIN_SIZE:
			var w = max(MIN_SIZE, rect.size.x)
			rect.size = Vector2i(w,max(MIN_SIZE, rect.size.y))
			rect.position = Vector2i(-w*0.5,0)
			
		var size_scale = round(800 / (max(rect.size.x,rect.size.y)))
		size_scale = size_scale / 4.0
		%MapData.scale = Vector2.ONE * size_scale
		%MapData.position.y = 30
		%MapContainer.custom_minimum_size = rect.size * 4 * size_scale
		%MapContainer.custom_minimum_size.y += 10
		%MapData.position.x = -4 * rect.position.x * size_scale
	else:
		$MiniMap.visible = false

func flipPlayerCoord():
	var r = %MapData.get_resourcev(playerCoord)
	if r == 3:
		%MapData.set_resourcev(playerCoord, 25)
	else:
		%MapData.set_resourcev(playerCoord, 3)
	create_tween().tween_callback(flipPlayerCoord).set_delay(0.3)

func setAllowUpgrades(allowUpgrades:bool):
	%HBoxActionUpgrades.visible = allowUpgrades
	$PanelContainer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM,Control.PRESET_MODE_MINSIZE)

func setAllowEmergencyExit(v:bool):
	%ActionEmergencyExitLabel.visible = v
	%ActionEmergencyExit.visible = v
	%ActionBackSeparator2.visible = v
	$PanelContainer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM,Control.PRESET_MODE_MINSIZE)

func moveIn(delay := false):
	if isIn:
		return
	
	isIn = true
	tween2.stop_all()
	tween2.remove_all()
	var s = get_viewport_rect().size
	$Tween.interpolate_property(self, "position:y", position.y, s.y - size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.3 if delay else 0.0)
	$Tween.start()
	
func moveOut(free := false):
	if not isIn:
		return
	
	isIn = false
	$Tween.stop_all()
	$Tween.remove_all()
	var s = get_viewport_rect().size
	tween2.interpolate_property(self, "position:y", position.y, s.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	if free:
		tween2.interpolate_callback(self, 0.31, "queue_free")
	tween2.start()
