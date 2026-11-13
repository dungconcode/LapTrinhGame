extends Node2D

class_name Map

const BORDER_TILE_OFFSETS1 = [Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1)]
const BORDER_TILE_OFFSETS2 = [
Vector2(0,0), Vector2(1,0), Vector2(0,1), Vector2(1,1),
Vector2(-1,0), Vector2(-1,1), Vector2(0,-1), Vector2(1,-1),
Vector2(2,0), Vector2(2,1), Vector2(0,2), Vector2(1,2)
]
const NEIGHBOR_TILE_OFFSETS1 = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1)]
const NEIGHBOR_TILE_OFFSETS2 = [
Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1),
Vector2(2,0),Vector2(-2,0),Vector2(0,2),Vector2(0,-2),
Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]
const NEIGHBOR_TILE_OFFSETS_DIAG = [Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1),Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]

const MAP_TO_TEXTURE_OFFSET_COORD := Vector2(0, 2)

const TILE_SCENE = preload("res://content/map/tile/Tile.tscn")
const RESOURCE_BORDER_OVERLAY = preload("res://content/map/border/ResourceBorderOverlay.tscn")

var BIOME_LIST := {
	"grey": Color("232532"),
	"red": Color("3c2436"),
	"yellow": Color("35221e"),
	"blue": Color("142137"),
	"green": Color("19383e")
}
var biomes := []

var layouts := {
	1:  Vector2(0,0),
	2:  Vector2(1,0),
	3:  Vector2(2,0),
	4:  Vector2(3,0),
	5:  Vector2(0,1),
	6:  Vector2(1,1),
	7:  Vector2(2,1),
	8:  Vector2(3,1),
	9:  Vector2(0,2),
	10:  Vector2(1,2),
	11:  Vector2(2,2),
	12:  Vector2(3,2),
	13:  Vector2(0,3),
	14:  Vector2(1,3),
	15:  Vector2(3,3),
}

var hardnessOffsets := {
	0:  Vector2(0,0),
	1:  Vector2(0,4),
	2:  Vector2(0,8),
	3:  Vector2(0,12),
	4:  Vector2(0,16),
	5:  Vector2(0,20),
}

const borderSpriteOffset = Vector2(12,12)
const mapToWorldOffset = Vector2(12,-72)

var tileData:MapData

var borderSprites := {} # all tile borders by coord
var tiles := {} # all tiles by coord

#key: coord of revealed tiles, value: with what resource they where revealed, used to re-reveal now changed tiles
var visibleTileCoords := {}
var tileCoordsToReveal := []
var tileDestroyedListeners := {}
var tileRevealedListeners := {}
var onRevealDecorators := []
var initialUsedRect:Rect2
var visuallyRevealedTiles := {}

# for iron progression
var startingIronCountByLayer := {}
var currentIronCountByLayer := {}

var tilesByType := {CONST.WATER:[],CONST.SAND:[],CONST.IRON:[]}

var dropDeltas := {}
var isFirstDrop := true

var lift

var pathfinder:Pathfinding

@onready var lights = $ViewportLights
@onready var tiles_node = $Tiles
@onready var bg_elements = $"%BackgroundElements"
@onready var tile_borders_node = $TileBorders
@onready var border_deco = $TileRender/BorderDecorations

## New Tile System by Raffa
var holeTexture : ImageTexture = ImageTexture.new()
var holeImage : Image = Image.new()

var rockFalloffTexture : ImageTexture = ImageTexture.new()
var rockFalloffImage : Image = Image.new()

var damageTexture : ImageTexture = ImageTexture.new()
var damageImage : Image = Image.new()

var bgCaveTexture : ImageTexture = ImageTexture.new()
var bgCaveImage : Image = Image.new()

var biomeColorTexture : ImageTexture = ImageTexture.new()
var biomeColorImage : Image = Image.new()

var noiseFactorTexture : ImageTexture = ImageTexture.new()
var noiseFactorImage : Image = Image.new()

var edge_scaling = 4
# This is now calculated and returned by the TileData class
# We have to keep a close eye on if the calc is correct / Raffa
var tilemap_size = Vector2.ONE
var viewport_crack_update := 0.0
@onready var fg_mat = $TileRender/MainStones.material
@onready var bg_mat = $BackgroundRender/BackgroundSprite.material
@onready var rock_tiles = $ViewportRocks/Rocks
@onready var viewport_crack_impact: SubViewport = $ViewportCrackImpact


func setTileData(tileDataInstance):
	if tileData:
		tileData.free()
	tileData = tileDataInstance
	if not tileData.get_parent():
		tileData.owner = null
		add_child(tileData)
		getTileData().position = -mapToWorldOffset
	Data.apply("map.depthpixels", tileData.getSize().y * GameWorld.TILE_SIZE)
	initialUsedRect = tileData.get_used_rect()

func init(fromDeserialize := false, defaultState := true):
	var rand = RandomNumberGenerator.new()
	rand.seed = Level.levelSeed
	borderSprites.clear()
	for s in tiles.values():
		if is_instance_valid(s):
			s.queue_free()
	tiles.clear()
	visibleTileCoords.clear()
	tileCoordsToReveal.clear()
	tileDestroyedListeners.clear()
	tileRevealedListeners.clear()
	startingIronCountByLayer.clear()
	currentIronCountByLayer.clear()
	for array in tilesByType.values():
		array.clear()
	dropDeltas.clear()
	if pathfinder:
		pathfinder.cleanup()
	
	border_deco.borderSprites = borderSprites
	border_deco.init()
	Style.init($Background)
	Style.init($BackgroundRender/BackgroundSprite)
	Style.init($TileRender/MainStones)
	tilesByType = {CONST.WATER:[],CONST.SAND:[],CONST.IRON:[]}
	Data.apply("map.tilesDestroyed", 0)
	
	tileData.visible = false
	# Use this for TileMap visualisation
#	tileData.modulate.a = 0.5
	
	for ironCell in tileData.get_resource_cells_by_id(Data.TILE_IRON):
		var layer = tileData.get_biome(ironCell.x, ironCell.y)
		startingIronCountByLayer[layer] = 1 + startingIronCountByLayer.get(layer, 0)
	for l in startingIronCountByLayer:
		currentIronCountByLayer[l] = startingIronCountByLayer[l]
	
	if not fromDeserialize:
		# tile data gets modified with creating chambers, so that should not be done on reload
		var clusterCenters = getResourceClusterTopLeft(Data.TILE_GADGET)
		for centerCoord in clusterCenters:
			addChamber(centerCoord, getSceneForTileType(Data.TILE_GADGET))
		
		clusterCenters = getResourceClusterTopLeft(Data.TILE_RELIC)
		for centerCoord in clusterCenters:
			addChamber(centerCoord, getSceneForTileType(Data.TILE_RELIC))
		
		clusterCenters = getResourceClusterTopLeft(Data.TILE_RELIC_SWITCH)
		for centerCoord in clusterCenters:
			addChamber(centerCoord, getSceneForTileType(Data.TILE_RELIC_SWITCH))
		
		clusterCenters = getResourceClusterTopLeft(Data.TILE_SUPPLEMENT)
		for centerCoord in clusterCenters:
			addChamber(centerCoord, getSceneForTileType(Data.TILE_SUPPLEMENT))
		
		if GameWorld.isChristmas and Level.loadout and Level.loadout.modeId == CONST.MODE_RELICHUNT:
			var skinAlreadyUnlocked = GameWorld.unlockedSkins.get("keeper2", []).has("skin3")
			var petAlreadyUnlocked = GameWorld.unlockedPets.has("pet7")
			if Level.loadout.keepers.any(func(x): return x.keeperId == "keeper2") and not skinAlreadyUnlocked:
				addGiftChamber("skin3")
			elif not petAlreadyUnlocked:
				addGiftChamber("pet7")

		if GameWorld.isHalloween:
			for c in tileData.get_resource_cells_by_id(Data.TILE_SAND):
				addChamber(c, preload("res://content/map/decorations/ornaments/FollowEye.tscn"))

		if GameWorld.useCustomCaveOrder and GameWorld.customCaveOrder and GameWorld.customCaveOrder.size() > 0:
			biomes.clear()
			biomes.append("grey")
			for caveId in GameWorld.customCaveOrder:
				# a bit stupid, but a nice way needs a refactor and probably does not matter in a measurable way. 
				# Refactoring would be to move the cave meta data out of the scene and into Data.
				var cave = Data.CAVE_SCENES[caveId].instantiate()
				biomes.append(cave.biome)
				cave.queue_free()
		else:
			# set up biomes
			biomes.clear()
			biomes.append("grey")
			if shouldGenerateDrillbertCave():
				biomes.append("blue")
			if rand.randf() > 0.4:
				biomes.append("green")
				if rand.randf() > 0.5:
					biomes.append("yellow")
					biomes.append("red")
				else:
					biomes.append("red")
					biomes.append("yellow")
			else:
				if rand.randf() > 0.5:
					biomes.append("yellow")
					if rand.randf() > 0.2:
						biomes.append("green")
						biomes.append("red")
					else:
						biomes.append("red")
						biomes.append("green")
				else:
					biomes.append("red")
					if rand.randf() > 0.2:
						biomes.append("green")
						biomes.append("yellow")
					else:
						biomes.append("yellow")
						biomes.append("green")
			if rand.randf() > 0.25:
				biomes.append("blue")
			else:
				biomes.insert(biomes.size() - 2, "blue")
		
		var availableBiomes = BIOME_LIST.keys().duplicate()
		for _i in range(1, 100):
			var biomeId = availableBiomes[rand.randi() % availableBiomes.size()]
			if biomeId == biomes[biomes.size() - 1] or biomeId == biomes[biomes.size() - 2]:
				continue
			biomes.append(biomeId)
			availableBiomes.erase(biomeId)
			if availableBiomes.size() == 0:
				availableBiomes = BIOME_LIST.keys().duplicate()
				availableBiomes.erase(biomeId)
		if biomes.size() < 30:
			for _i in 4:
				availableBiomes = BIOME_LIST.keys().duplicate()
				Utils.shuffle(availableBiomes,rand)
				biomes.append_array(availableBiomes)
	
	pathfinder = Pathfinding.new()
	Achievements.addIfOpen(self, "MINE_ALL")
	
	# prepareTilemapAndProcgen():
	tilemap_size = tileData.getMaxSize()

	# Setup viewports
	var viewport_size = tilemap_size * GameWorld.TILE_SIZE
	$ViewportRocks.size = viewport_size
	$ViewportCrackImpact.size = viewport_size
	$ViewportLights.set_size(viewport_size)
	$ViewportBackgroundAlpha.size = viewport_size
	$ViewportLights.map_to_world_offset = mapToWorldOffset
	$TileRender.position = Vector2((-viewport_size.x/2.0)-GameWorld.HALF_TILE_SIZE, -GameWorld.TILE_SIZE)
	$BackgroundRender.position = Vector2((-viewport_size.x/2.0)-GameWorld.HALF_TILE_SIZE, -GameWorld.TILE_SIZE)

	rock_tiles.position.x = tilemap_size.x/2 * GameWorld.TILE_SIZE
	$LightSprite.position.x = (-tilemap_size.x/2 * GameWorld.TILE_SIZE) - mapToWorldOffset.x
	$ViewportLights.sprite = $LightSprite
	border_deco.position.x = (tilemap_size.x/2 * GameWorld.TILE_SIZE) + GameWorld.TILE_SIZE
	bg_elements.position.x = (tilemap_size.x/2 * GameWorld.TILE_SIZE) + GameWorld.HALF_TILE_SIZE
	bg_elements.position.y = GameWorld.TILE_SIZE

	holeImage = prepareTextureAndImage(holeTexture, edge_scaling, Image.FORMAT_RGB8, false, Color.BLACK) # linear filter - DONE
	bgCaveImage = prepareTextureAndImage(bgCaveTexture, 1, Image.FORMAT_RGB8, true, Color.BLACK) # linear filter - DONE
	rockFalloffImage = prepareTextureAndImage(rockFalloffTexture, 1, Image.FORMAT_RGB8, false, Color.BLACK) # linear filter - DONE
	damageImage = prepareTextureAndImage(damageTexture, 2, Image.FORMAT_RGBA8, false, Color(0.0, 0.0, 0.0, 1.0)) # linear filter - DONE
	noiseFactorImage = prepareTextureAndImage(noiseFactorTexture, 1, Image.FORMAT_RGB8, false, Color.WHITE) # linear filter - DONE
	biomeColorImage = prepareTextureAndImage(biomeColorTexture, 1, Image.FORMAT_RGB8, false, Color.BLACK) # NEAREST filter - DONE
	
	var map_scale:Vector2 = viewport_size / Vector2(3768.0, 3768.0)
	
	fg_mat.set_shader_parameter("mask_map", holeTexture)
	fg_mat.set_shader_parameter("damage_map", damageTexture)
	fg_mat.set_shader_parameter("rock_falloff_map", rockFalloffTexture)
	fg_mat.set_shader_parameter("mask_noise_factor_map", noiseFactorTexture)
	fg_mat.set_shader_parameter("base_scale", map_scale)
	fg_mat.set_shader_parameter("pixel_size", viewport_size)
	bg_mat.set_shader_parameter("mask_map", holeTexture)
	bg_mat.set_shader_parameter("cave_map", bgCaveTexture)
	bg_mat.set_shader_parameter("base_scale", map_scale)
	bg_mat.set_shader_parameter("pixel_size", viewport_size)
	
	# setRockTiles()
	var max_size = tilemap_size

	var bg_cave_spread = [
		Vector2.LEFT, Vector2.RIGHT,
		Vector2.UP, Vector2.DOWN,
		Vector2(-1, -1), Vector2(1, 1),
		Vector2(-1, 1), Vector2(1, -1),
		]
	
	
	for m_x_e in max_size.x:
		rock_tiles.set_cell(MapData.DEFAULT_LAYER, Vector2(m_x_e - max_size.x/2, -2), 5, Vector2())
	
	for m_x in max_size.x:
		for m_y in max_size.y:
			# due to dome gap bug... a bit nasty, but hey /Raffa
			var adj_m_y = min(m_y+1, max_size.y-1)
			
			# Get hardness and set the hardness map.
			# This is now only set to include the maximum hardness to have
			# smooth walls on the maximum hardness tiles, but could also set to
			# include color values of generic hardness values to influence the map
			var x_coord = m_x - max_size.x/2
			var y_coord = m_y - 1

			var bg_cave_col = bgCaveImage.get_pixel(m_x, adj_m_y)
			var bg_cave_img_size = bgCaveImage.get_size()
			var resource = tileData.get_resource(x_coord, y_coord)
			if resource < 10 and resource != -1:
				bg_cave_col.r = 1.0

			var hardness = tileData.get_hardness(x_coord, y_coord)
			if hardness != -1:
				rock_tiles.set_cell(MapData.DEFAULT_LAYER, Vector2(x_coord, y_coord), hardness, Vector2(0,0))
				var noise_factor_color = Color.BLACK
				if hardness == 5:
					noise_factor_color.r = 1.0
					bg_cave_col.r = 1.0

				# green channel used for shortening the falloff
				hardness = 10 if hardness == 5 else hardness * 0.5
				noise_factor_color.g = float(hardness) / 5.0
				noiseFactorImage.set_pixel(m_x, adj_m_y, noise_factor_color)
			else:
				rock_tiles.set_cell(MapData.DEFAULT_LAYER, Vector2(x_coord, y_coord), 5, Vector2(0,0))
				bg_cave_col.g = 1.0
			
			
			if bg_cave_col.r == 1.0:
				for bcs in bg_cave_spread:
					var spread_coord = Vector2(m_x, m_y)+bcs
					# Avoid setting a pixel outside the image size
					if (spread_coord.x < 0 or spread_coord.y < 0
					or spread_coord.x > bg_cave_img_size.x
					or spread_coord.y > bg_cave_img_size.y):
						continue

					var bg_cave_col_s = bgCaveImage.get_pixelv(spread_coord)
					bg_cave_col_s.b = 1.0
					bg_cave_col.b = 1.0
					bgCaveImage.set_pixelv(spread_coord, bg_cave_col_s)

			bgCaveImage.set_pixel(m_x, adj_m_y, bg_cave_col)
			
			var biome = tileData.get_biome(x_coord, y_coord - 1)
			if biome >= 0:
				biomeColorImage.set_pixel(m_x, m_y, BIOME_LIST[biomes[biome]])
			else:
				biomeColorImage.set_pixel(m_x, m_y, BIOME_LIST[biomes[0]])

	bgCaveImage.generate_mipmaps()
	noiseFactorTexture.set_image(noiseFactorImage)
	biomeColorTexture.set_image(biomeColorImage)
	bgCaveTexture = ImageTexture.create_from_image(bgCaveImage)
	fg_mat.set_shader_parameter("mask_noise_factor_map", noiseFactorTexture)
	fg_mat.set_shader_parameter("biome_color_map", biomeColorTexture)
	bg_mat.set_shader_parameter("biome_color_map", biomeColorTexture)
	bg_mat.set_shader_parameter("cave_map", bgCaveTexture)
	
	
	var endY = tilemap_size.y * GameWorld.TILE_SIZE
	$CentralMarker.init(endY)
	
	if GameWorld.devMode and OS.has_feature("editor"):
		ResourceSaver.save(Level.map.getTileData().pack(), "res://content/map/data/TileDataInitial.tscn")

func getResourceClusterTopLeft(tileType:int) -> Array:
	var resourceCells = tileData.get_resource_cells_by_id(tileType)
	var clustersCenters = []
	while resourceCells.size() > 0:
		var sourceCell = resourceCells.pop_back()
		var newCluster = []
		var openCells = [sourceCell]
		while openCells.size() > 0:
			var currentCell: Vector2i = openCells.pop_back() as Vector2i
			newCluster.append(currentCell)
			getTileData().set_resourcev(currentCell, Data.TILE_DIRT_START)
			resourceCells.erase(currentCell)
			for offset in NEIGHBOR_TILE_OFFSETS1:
				var neighborCell = Vector2(currentCell) + offset
				var otherCellId = getTileData().get_resourcev(neighborCell)
				if otherCellId == tileType and not newCluster.has(neighborCell) and not openCells.has(neighborCell):
					openCells.append(neighborCell)
			
		var topLeft = Vector2(9999,9999)
		for cell in newCluster:
			topLeft.x = min(topLeft.x, cell.x)
			topLeft.y = min(topLeft.y, cell.y)
		clustersCenters.append(topLeft)
	return clustersCenters

func _ready():
	for bgGradientNodes in get_tree().get_nodes_in_group("shader-background-gradient"):
		bgGradientNodes.material.set_shader_parameter("grad_length", 100.0*$"%Background".scale.y)

func shouldGenerateDrillbertCave() -> bool:
	return GameWorld.isAprilFools and Level.loadout and Level.loadout.modeId == CONST.MODE_RELICHUNT and not GameWorld.unlockedRunModifiers.has("drillbert")

func addGiftChamber(giftType:String):
	 #gift chamber uses own randomness to avoid messing up the rest of the generation
	var biomes := [3,4,5]
	biomes.shuffle()
	for biomeIndex in biomes:
		var cells = getTileData().get_biome_cells_by_index(biomeIndex)
		if cells.size() < 50:
			continue
		for i in 20:
			var baseCoord = cells[randi() % cells.size()]
			var free := true
			for xOff in 2:
				for yOff in 2:
					var r = tileData.get_resource(baseCoord.x + xOff, baseCoord.y + yOff)
					free = free and (r == Data.TILE_DIRT_START)
			if free:
				var chamber = addChamber(baseCoord, preload("res://content/map/chamber/gift/GiftChamber.tscn"))
				chamber.giftType = giftType
				return

func prepareTextureAndImage(texture:ImageTexture, scaling:float, image_format:int, create_mipmaps:bool, fill_color:Color) -> Image:
	var image: Image = Image.create(tilemap_size.x * scaling, tilemap_size.y * scaling, create_mipmaps, image_format)
	image.fill(fill_color)
	texture = ImageTexture.create_from_image(image)
	return image

func generateCaves(minDistanceToCenter := 10):
	var rand = RandomNumberGenerator.new()
	rand.seed = Level.levelSeed
	var caveScenesById = Data.CAVE_SCENES.duplicate()

	var cavePackeScenes := []
	# SPECIAL CAVES
	if Level.loadout.modeId == CONST.MODE_RELICHUNT:
		if GameWorld.isPetUnlockable():
			cavePackeScenes.append(preload("res://content/map/chamber/nest/NestCave.tscn"))

	if GameWorld.useCustomCaveOrder and GameWorld.customCaveOrder and GameWorld.customCaveOrder.size() > 0:
		for caveId in GameWorld.customCaveOrder:
			if caveScenesById.has(caveId):
				cavePackeScenes.append(caveScenesById[caveId])
	else:
		for caveId in Data.CAVE_SCENES:
			if caveScenesById.has(caveId):
				cavePackeScenes.append(caveScenesById[caveId])
		Utils.shuffle(cavePackeScenes,rand)

	if Level.loadout.modeId == CONST.MODE_RELICHUNT:
		for keeper in Level.loadout.keepers:
			if keeper.keeperId == "keeper1":
				if GameWorld.isHalloween and Level.loadout.modeId == CONST.MODE_RELICHUNT:
					cavePackeScenes.insert(0, preload("res://content/caves/halloweencave/HalloweenSkeletonCave.tscn"))
					break
		if GameWorld.isLunarNewYear and not GameWorld.unlockedPets.has("pet8"):
			cavePackeScenes.insert(0, preload("res://content/caves/dragoncave/LunarNewYearDragonCave.tscn"))
		if shouldGenerateDrillbertCave():
			cavePackeScenes.insert(0, preload("res://content/caves/drillicave/DrillbertCave.tscn"))
	
	var availableCaves:Array
	var caveCount := {}
	var maxLayer = startingIronCountByLayer.size()
	for layerIndex in maxLayer:
		if availableCaves.is_empty():
			availableCaves = cavePackeScenes.duplicate()
		for cavePackedScene in availableCaves:
			var cave = cavePackedScene.instantiate() # yeah this is shit, but probably not noticable
			var biomeFits = cave.biome == "" or biomes[layerIndex] == cave.biome 
			var minLayerFits = cave.minLayer <= layerIndex
			var relativeDepth = layerIndex / float(maxLayer)
			var minDepthFits = round(relativeDepth * cave.minRelativeDepth) <= layerIndex
			var maxDepthFits = layerIndex <= round(maxLayer * cave.maxRelativeDepth)
			var withinAllowedCount = caveCount.get(cavePackedScene, 0) < cave.maxCount
			if biomeFits and minLayerFits and minDepthFits and maxDepthFits and withinAllowedCount:
				addCave(rand, cave, layerIndex, minDistanceToCenter)
				availableCaves.erase(cavePackedScene)
				caveCount[cavePackedScene] = caveCount.get(cavePackedScene, 0) + 1
				break
			else:
				cave.queue_free()

func getBiomeColorByCoord(_coord:Vector2):
	var biome = tileData.get_biomev(_coord)
	var coord_biome_color = BIOME_LIST[biomes[biome]]
	return coord_biome_color

func addTileDamage(hit_power, health, _direction, _position):
	flashCracks(_position)
	setTileDamage(health, _direction, _position)

func setTileDamage(health, direction, _position):
	# Fix for the dome gap, sucks but for now it's the best solution :( / Raffa
	_position += Vector2(0, 24)
	
	if health != 0:
		health = ease((health*0.6)+0.4, 1.2)
	
	if abs(direction.x) > abs(direction.y):
		direction.y = 0
	else:
		direction.x = 0
	
	var from_dir = direction.normalized().round()
	var modded_pos = (_position / GameWorld.TILE_SIZE) + Vector2(tilemap_size.x/2, 0.0) + Vector2.DOWN
	
	modded_pos *= 2
	for x in 2:
		for y in 2:
			var current_pos = modded_pos + Vector2(x, y)
			var current_color_center = damageImage.get_pixelv(current_pos)
			current_color_center.b = health
			damageImage.set_pixelv(current_pos, current_color_center)
			
			if from_dir.x == -1:
				# damage left
				var current_color = damageImage.get_pixelv(current_pos)
				current_color.r = health
				damageImage.set_pixelv(current_pos, current_color)

			elif from_dir.x == 1:
				# damage right
				var current_color = damageImage.get_pixelv(current_pos+(Vector2.RIGHT*2))
				current_color.r = health
				damageImage.set_pixelv(current_pos+(Vector2.RIGHT*2), current_color)

			elif from_dir.y == -1:
				# damage down
				var current_color = damageImage.get_pixelv(current_pos)
				current_color.g = health
				damageImage.set_pixelv(current_pos, current_color)

			elif from_dir.y == 1:
				# damage up
				var current_color = damageImage.get_pixelv(current_pos+(Vector2.DOWN*2))
				current_color.g = health
				damageImage.set_pixelv(current_pos+(Vector2.DOWN*2), current_color)
	damageTexture.set_image(damageImage)
	fg_mat.set_shader_parameter("damage_map", damageTexture)

const CrackImpact = preload("res://content/map/tile/CrackImpact.tscn")
func flashCracks(_pos:Vector2):
	# Fix for the dome gap, sucks but for now it's the best solution :( / Raffa
	var tile_pos = _pos + (Vector2(tilemap_size.x/2, 0.0) * GameWorld.TILE_SIZE)
	tile_pos += Vector2(12, 58)
	var new_impact = CrackImpact.instantiate()
	new_impact.position = tile_pos
	viewport_crack_impact.add_child(new_impact)
	viewport_crack_update = 0.1

func removeTileVisually(tileCoord:Vector2):
	visuallyRevealedTiles.erase(tileCoord)
	# Fix for the dome gap, sucks but for now it's the best solution :( / Raffa
	tileCoord += MAP_TO_TEXTURE_OFFSET_COORD
	
	var draw_pos_es = (Vector2(tileCoord.x, tileCoord.y) + Vector2(tilemap_size.x/2, 0)) * edge_scaling
	var draw_pos = (Vector2(tileCoord.x, tileCoord.y) + Vector2(tilemap_size.x/2, 0))
	
	for x in edge_scaling:
		for y in edge_scaling:
			holeImage.set_pixelv(draw_pos_es + Vector2(x,y), Color.WHITE)

	var rock_falloff_color = rockFalloffImage.get_pixelv(draw_pos)
	rock_falloff_color.r = 1.0
	rockFalloffImage.set_pixelv(draw_pos, rock_falloff_color)
	
	var offsets = get("BORDER_TILE_OFFSETS" + str(Data.of("map.revealdistance")))
	for offset in offsets:
		var drawpos_offset = draw_pos + offset
		if drawpos_offset.y < 0:
			continue
		var rock_falloff_color_offset = rockFalloffImage.get_pixelv(drawpos_offset)
		rock_falloff_color_offset.g = 1.0
		rockFalloffImage.set_pixelv(drawpos_offset, rock_falloff_color_offset)
	
	# Updating / Clearing Cracks, this is hacky! But it works ... sweat emoji /Raffa
	var rock_falloff_image_size := rockFalloffImage.get_size()
	# Check if coord is valid
	if not ((draw_pos.x < 0 or draw_pos.x > rock_falloff_image_size.x)
		or (draw_pos.y < 0 or draw_pos.y > rock_falloff_image_size.y)):
		# Check if cell is empty or not (1 = empty)
		var cell_color:float = rockFalloffImage.get_pixelv(draw_pos).r
		if cell_color == 1:
			for x in 2:
				for y in 2:
					# remove right red (at +1)
					var red_coord = ((draw_pos)*2) + Vector2(x+2, y)
					var oc_r:Color = damageImage.get_pixelv(red_coord)
					oc_r.r = 0
					damageImage.set_pixelv(red_coord, oc_r)
			
					# remove bottom green (at +1)
					var green_coord = ((draw_pos)*2) + Vector2(x, y+2)
					var oc_g:Color = damageImage.get_pixelv(green_coord)
					oc_g.g = 0
					damageImage.set_pixelv(green_coord, oc_g)
			
					# make center black
					var final_coord = ((draw_pos)*2) + Vector2(x, y)
					damageImage.set_pixelv(final_coord, Color.BLACK)
	
	damageTexture.set_image(damageImage)
	holeTexture.set_image(holeImage)
	rockFalloffTexture.set_image(rockFalloffImage)
	
	fg_mat.set_shader_parameter("damage_map", damageTexture)
	fg_mat.set_shader_parameter("mask_map", holeTexture)
	fg_mat.set_shader_parameter("rock_falloff_map", rockFalloffTexture)
	bg_mat.set_shader_parameter("mask_map", holeTexture)

func floodRevealTiles(forceUpdate := false):
	var closedCells := {}
	var offsets = get("NEIGHBOR_TILE_OFFSETS" + str(Data.of("map.revealdistance")))
	while not tileCoordsToReveal.is_empty():
		var cell:Vector2 = tileCoordsToReveal.pop_back()
		closedCells[cell] = true
		if tileData.get_hardnessv(cell) <= -1:
#			prints("ignore because out of bounds", cell)
			continue
		#prints("reveal around cell", cell)
		var resv = tileData.get_resourcev(cell)
		if resv == -1:
			#prints("empty cell, reveal neighbors", cell)
			if not visibleTileCoords.has(cell) or visibleTileCoords[cell] != -1:
				visibleTileCoords[cell] = -1
				revealTile(cell)
				onTileRemoved(cell)
				removeTileVisually(cell)
			
			# tile is empty itself, also reveal its neighbors
			for d in offsets:
				if closedCells.has(cell + d):
#					prints("cell already about to revealed, skipping", cell+d)
					continue
				if visibleTileCoords.has(cell + d) and not forceUpdate:
#					prints("cell already visible, skipping", cell+d)
					continue
				
#				prints("going to reveal", cell + d)
				tileCoordsToReveal.append(cell + d)
		else:
#			prints("filled cell, reveal it ", cell)
			if not visibleTileCoords.has(cell) or visibleTileCoords[cell] != resv:
				revealTile(cell)

#used by scanner to only update rock formations of border tiles
func removeAllEmptyBorderTilesVisually():
	var map := {}
	for x in visibleTileCoords:
		if visibleTileCoords[x] == -1:
			map[x] = true

	for x in map:
		var count := 0
		for y in NEIGHBOR_TILE_OFFSETS1:
			if map.has(x+y):
				count+= 1

		#not fully surrounded by empty cells == bordering solid tile
		if count <4:
			removeTileVisually(x)

# This *fully* reveals a tile. It is used to e.g. reveal a discovered resource tile.
# It should not be used to reveal normal rock tiles.
func revealTileVisually(_pos:Vector2):
	if visuallyRevealedTiles.has(_pos):
		return
	visuallyRevealedTiles[_pos] = true
	
	# Fix for the dome gap, sucks but for now it's the best solution :( / Raffa
	_pos += Vector2.DOWN
	if _pos.y < 0:
		return
	
	var draw_pos = (Vector2(floor(_pos.x), floor(_pos.y+1)) + Vector2(tilemap_size.x/2, 0))
	var rock_falloff_color = rockFalloffImage.get_pixelv(draw_pos)
	rock_falloff_color.r = 1.0
	rockFalloffImage.set_pixelv(draw_pos, rock_falloff_color)
	rockFalloffTexture.set_image(rockFalloffImage)
	fg_mat.set_shader_parameter("rock_falloff_map", rockFalloffTexture)

func revealInitialState(startVector := Vector2(0, -1)):
	tileCoordsToReveal.append(startVector)
	floodRevealTiles()
	
	onRevealDecorators.clear()
	var hiddenCaveCells := []
	for cell in tileData.getRevealedCells():
		if not visibleTileCoords.has(cell):
			hiddenCaveCells.append(cell)
	var currentDecorator
	var closedCells := []
	
	while not hiddenCaveCells.is_empty():
		var starterCell = hiddenCaveCells.pop_back()
		var openCells := [starterCell]
		currentDecorator = preload("res://content/map/decorations/OnRevealDecorator.gd").new()
		onRevealDecorators.append(currentDecorator)
		addTileRevealedListener(currentDecorator, starterCell)
		while openCells.size() > 0:
			var cell = openCells.pop_back()
			closedCells.append(cell)
			hiddenCaveCells.erase(cell)
			if tileData.get_resourcev(cell) == -1 and tileData.get_hardnessv(cell) >= 0:
				currentDecorator.addCell(cell)
				for d in CONST.DIRECTIONS:
					var newCoord = Vector2(cell) + d
					if not closedCells.has(newCoord) and not openCells.has(newCoord):
						openCells.append(newCoord)

func _process(delta):
	if GameWorld.devMode and Input.is_action_just_pressed("num6"):
		var i = randi()
		holeImage.save_png("../" + str(i) + "holeImage.png")
		rockFalloffImage.save_png("../" + str(i) + "rockFalloffImage.png")
		damageImage.save_png("../" + str(i) + "damageImage.png")
		bgCaveImage.save_png("../" + str(i) + "bgCaveImage.png")
		biomeColorImage.save_png("../" + str(i) + "biomeColorImage.png")
		noiseFactorImage.save_png("../" + str(i) + "noiseFactorImage.png")
	if not GameWorld.paused:
		if viewport_crack_update > 0.0:
			viewport_crack_update -= delta
			viewport_crack_impact.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		else:
			viewport_crack_impact.render_target_update_mode = SubViewport.UPDATE_DISABLED

func growTile(coord:Vector2, type:int):
	tileData.set_resourcev(coord, type)
	revealTile(coord)

func revealTile(coord:Vector2):
	var invalids := []
	if tileRevealedListeners.has(coord):
		for listener in tileRevealedListeners[coord]:
			if is_instance_valid(listener):
				listener.tileRevealed(coord)
			else:
				invalids.append(listener)
		for invalid in invalids:
			tileRevealedListeners.erase(invalid)
	
	var typeId:int = tileData.get_resource(coord.x, coord.y)
	if typeId == Data.TILE_EMPTY:
		return
	
	if tiles.has(coord):
		return
	
	var tile = TILE_SCENE.instantiate()
	var biomeId:int = tileData.get_biome(coord.x, coord.y)
	tile.layer = biomeId
	tile.biome = biomes[tile.layer]
	tile.position = coord * GameWorld.TILE_SIZE
	tile.coord = coord
		
	tile.hardness = tileData.get_hardness(coord.x, coord.y)

	tile.type = Data.TILE_ID_TO_STRING_MAP.get(typeId, "dirt")
	match tile.type:
		CONST.IRON:
			tile.richness = Data.ofOr("map.ironrichness", 2)
			revealTileVisually(coord)
		CONST.SAND:
			tile.richness = Data.ofOr("map.cobaltrichness", 2)
			revealTileVisually(coord)
		CONST.WATER:
			tile.richness = Data.ofOr("map.waterrichness", 2.5)
			revealTileVisually(coord)
	tiles[coord] = tile 
	
	if tilesByType.has(tile.type):
		tilesByType[tile.type].append(tile)
	tile.connect("destroyed", Callable(self, "destroyTile").bind(tile))
	
	tiles_node.add_child(tile)

	# Allow border tiles to fade correctly at edges of the map
	visibleTileCoords[coord] = typeId

func destroyTile(tile, withDropsAndSound := true):
	Data.changeByInt("map.tilesDestroyed", 1)
	Recorder.recordTileDestroyed(tile.coord)
	if withDropsAndSound:
		var sound
		match tile.type:
			CONST.IRON:
				sound = $TileDestroyedIron.duplicate(Node.DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
			CONST.WATER:
				sound = $TileDestroyedWater.duplicate(Node.DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
			CONST.SAND:
				sound = $TileDestroyedSand.duplicate(Node.DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
			CONST.GADGET:
				sound = $TileDestroyedChamber.duplicate(Node.DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
			CONST.POWERCORE:
				sound = $TileDestroyedChamber.duplicate(Node.DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
			CONST.RELIC:
				sound = $TileDestroyedChamber.duplicate(Node.DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
			_:
				sound = $TileDestroyed.duplicate(Node.DuplicateFlags.DUPLICATE_USE_INSTANTIATION)
		sound.setSimulatedPosition(tile.global_position)
		add_child(sound)
		sound.play()
	
		if tile.type == CONST.IRON or tile.type == CONST.SAND or tile.type == CONST.WATER:
			var goalRichness = tile.richness * Data.ofOr("resourcemodifiers.richness." + tile.type, 1.0)
			var drops = floor(goalRichness - 1 + (randi() % 3)) #tile richness is currently not seed based @TODO
			if tile.type == CONST.IRON:
				if isFirstDrop:
					#ensure first drop is constant
					isFirstDrop = false
					drops = 2
			var newDelta = dropDeltas.get(tile.type, 0) + drops - goalRichness
			if newDelta >= 3:
				drops -= 1
				newDelta -= 1
			elif newDelta <= -3:
				drops += 1
				newDelta += 1
			dropDeltas[tile.type] = newDelta
			
			if tile.type == CONST.SAND and drops < 3 and Level.loadout.modeId == CONST.MODE_RELICHUNT and Level.loadout.difficulty <= 0:
				# rubberbanding: chance for extra sand if low on health
				var sandWithFloating = Data.of("inventory.sand") + Data.of("inventory.floatingsand")
				if Data.of("dome.health") < 350 - 60 * sandWithFloating:
					drops += 1
			if drops < 3 and Level.difficulty() * 0.1 < -randf():
				drops += 1
			
			for _i in range(0, drops):
				var drop = Data.DROP_SCENES.get(tile.type).instantiate()
				drop.position = tile.global_position + 0.6 * Vector2(GameWorld.HALF_TILE_SIZE - randf()*GameWorld.TILE_SIZE, GameWorld.HALF_TILE_SIZE - randf()*GameWorld.TILE_SIZE)
				drop.apply_central_impulse(Vector2(0, 40).rotated(randf() * TAU))
				call_deferred("addDrop", drop)
				GameWorld.incrementRunStat("resources_mined")
	
	if tile.type == CONST.IRON:
		currentIronCountByLayer[tile.layer] = currentIronCountByLayer[tile.layer] - 1
	
	if tile.hardness == 5:
		# border tile destroyed, make sure there are physical tiles around now
		buildBorderAroundTile(tile.coord, tileData.get_biomev(tile.coord))
	
	tiles.erase(tile.coord)
	for t in tilesByType.values():
		t.erase(tile)
	tilesByType.get(tile.type, {}).erase(tile)
	tile.queue_free()
	
	onTileRemoved(tile.coord)
#	for d in CONST.DIRECTIONS:
#		tileCoordsToReveal.append(tile.coord + d)
	tileCoordsToReveal.append(tile.coord)
	floodRevealTiles()

func onTileRemoved(tileCoord:Vector2):
	tileData.clear_resource(tileCoord)
	
	for listener in tileDestroyedListeners.get(tileCoord, []):
		listener.tileDestroyed(tileCoord)
	
	pathfinder.add_point_in_coord(tileCoord)
	
	for n in NEIGHBOR_TILE_OFFSETS1:
		var c = n + tileCoord
		if not tiles.has(c):
			pathfinder.try_connect_coord(tileCoord, c)
	
	updateBorderSpriteOfTileCoord(tileCoord)
	
	if tileCoord.x == 0 and lift:
		updateLiftLength()

func updateBorderSpriteOfTileCoord(tileCoord:Vector2):
	for x in range(-1, 1):
		for y in range(-1, 1):
			updateBorderSprite(tileCoord.x + x, tileCoord.y + y)

func changeTileType(tile, typeId:int):
	tile.setType(Data.TILE_ID_TO_STRING_MAP.get(typeId, "dirt"))
	getTileData().set_resourcev(tile.coord, typeId)
	updateBorderSpriteOfTileCoord(tile.coord)
	Recorder.recordTileChangedType(tile.coord, typeId)

# listener should implement
#func tileRevealed(tileCoord:Vector2):
func addTileRevealedListener(listener, coord:Vector2):
	var listeners:Array
	
	if tileRevealedListeners.has(coord):
		listeners = tileRevealedListeners[coord]
	else:
		listeners = []
		tileRevealedListeners[coord] = listeners
	listeners.append(listener)

func removeTileRevealedListener(listener, coord:Vector2):
	if tileRevealedListeners.has(coord):
		var listeners = tileRevealedListeners.get(coord)
		listeners.erase(listener)
		tileRevealedListeners[coord] = listeners

# listener should implement
#func tileDestroyed(tileCoord:Vector2):
func addTileDestroyedListener(listener, coord:Vector2):
	var listeners:Array
	if tileDestroyedListeners.has(coord):
		listeners = tileDestroyedListeners[coord]
	else:
		listeners = []
		tileDestroyedListeners[coord] = listeners
	listeners.append(listener)

func removeTileDestroyedListener(listener, coord:Vector2):
	if tileDestroyedListeners.has(coord):
		var listeners = tileDestroyedListeners.get(coord)
		listeners.erase(listener)
		tileDestroyedListeners[coord] = listeners

func findPath(fromPos:Vector2, toPos:Vector2):
	var fromCoord = Vector2(getTileCoord(fromPos)) * GameWorld.TILE_SIZE + CONST.TILE_OFFSET
	if fromCoord.y < 0:
		fromCoord = Vector2(0, -1) * GameWorld.TILE_SIZE + CONST.TILE_OFFSET
	var toCoord = Vector2(getTileCoord(toPos)) * GameWorld.TILE_SIZE + CONST.TILE_OFFSET
	
	return pathfinder.findPath(fromCoord,toCoord)

func updateBorderSprite(x:int, y:int):
	var key = Vector2(x, y)
	border_deco.markDirtyTile(key)
	var r_tl:int = tileData.get_resource(x, y)
	var r_tr:int = tileData.get_resource(x + 1, y)
	var r_br:int = tileData.get_resource(x + 1, y + 1)
	var r_bl:int = tileData.get_resource(x, y + 1)
	var borderLayout = int(r_tl > Data.TILE_EMPTY) * 1 + int(r_tr > Data.TILE_EMPTY) * 2 + int(r_br > Data.TILE_EMPTY) * 4 + int(r_bl > Data.TILE_EMPTY) * 8 # <- sorry
	var tileMeta = borderSprites.get(key, null)
	if borderLayout > 0:
		if not tileMeta:
			var biome_id_tl:int = tileData.get_biome(x, y)
			var biome_id_tr:int = tileData.get_biome(x+1, y)
			var biome_id_bl:int = tileData.get_biome(x, y+1)
			var biome_id_br:int = tileData.get_biome(x+1, y+1)
			var biomeEdgeCase := biome_id_tl != biome_id_tr or biome_id_tr != biome_id_bl or biome_id_bl != biome_id_br
			var biome := "mixed"
			if not biomeEdgeCase:
				biome = biomes[biome_id_tl]
			tileMeta = [borderLayout, biome, {}]
			borderSprites[key] = tileMeta
			
			var overlays:Dictionary = tileMeta[2]
			for typeId in [Data.TILE_IRON, Data.TILE_SAND, Data.TILE_WATER]:
				if r_tl == typeId or r_tr == typeId or r_bl == typeId or r_br == typeId:
					var overlay = RESOURCE_BORDER_OVERLAY.instantiate()
					overlay.material = overlay.material.duplicate()
					overlay.position.x = x * GameWorld.TILE_SIZE + borderSpriteOffset.x
					overlay.position.y = y * GameWorld.TILE_SIZE + borderSpriteOffset.y
					tile_borders_node.add_child(overlay)
					overlays[typeId] = overlay
					Style.init(overlay)
		
		assert(tileMeta.size() == 3)
		tileMeta[0] = borderLayout
		
		var overlays:Dictionary = tileMeta[2]
		for ok in tileMeta[2]:
			var offset := Vector2()
			match ok:
				Data.TILE_IRON:
					offset.y += 8
				Data.TILE_WATER:
					offset.y += 4
			overlays[ok].set_frame_coords(layouts[borderLayout] + offset)
			overlays[ok].material.set_shader_parameter("frame_coords", layouts[borderLayout] + offset)
			overlays[ok].material.set_shader_parameter("hide_tl", float(r_tl != ok))
			overlays[ok].material.set_shader_parameter("hide_tr", float(r_tr != ok))
			overlays[ok].material.set_shader_parameter("hide_bl", float(r_bl != ok))
			overlays[ok].material.set_shader_parameter("hide_br", float(r_br != ok))
	elif borderSprites.has(key):
		assert(tileMeta.size() == 3)
		for ok in tileMeta[2]:
			tileMeta[2][ok].queue_free()
		borderSprites.erase(key)
		border_deco.markDirtyTile(key)

func addTileOverlayEffect(overlay):
	$TileOverlays.add_child(overlay)

func getSceneForTileType(tileType:int) -> PackedScene:
	match tileType:
		Data.TILE_GADGET: return preload("res://content/map/chamber/gadget/GadgetChamber.tscn")
		Data.TILE_RELIC: return preload("res://content/map/chamber/relic/RelicChamber.tscn")
		Data.TILE_NEST: return preload("res://content/map/chamber/nest/NestCave.tscn")
		Data.TILE_RELIC_SWITCH: return preload("res://content/map/chamber/relicswitch/RelicSwitchChamber.tscn")
		Data.TILE_SUPPLEMENT: return preload("res://content/map/chamber/supplement/PowerCoreChamber.tscn")
		_: return null

func addChamber(coord:Vector2, scene:PackedScene):
	var chamber = scene.instantiate()
	addLandmark(coord, chamber)
	for c in chamber.tileCoords:
		var absCoord = chamber.coord + Vector2(c)
		addTileDestroyedListener(chamber, absCoord)
		tileData.set_resourcev(absCoord, chamber.getTileType())
		
	return chamber

func addCave(rand, cave, biomeIndex, minDistanceToCenter):
	cave.updateUsedTileCoords()

	# try for a few times to find a suitable spot for the cave
	for _i in 30:
		var cells = tileData.get_biome_cells_by_index(biomeIndex)
		if cells.size() < cave.tileCoords.size():
			return
		
		var cell = cells[rand.randi() % cells.size()]
		if abs(cell.x) < minDistanceToCenter:
			continue
		
		if not tileData.is_area_free(cell, cave.tileCoords):
			continue
		
		addLandmark(cell, cave)
		for c in cave.tileCoords:
			var absCoord = Vector2(cell) + c
			tileData.clear_resource(absCoord)
		return
	
	Logger.error("failed to place cave", "Map.addCave", {"biomeIndex": biomeIndex, "cave": cave.scene_file_path})

func addLandmark(coord:Vector2, landmark):
	landmark.place(coord)
	var landmarkBiome = tileData.get_biomev(landmark.coord)
#	var landmarkHardness = tileData.get_hardnessv(landmark.coord)
	for c in landmark.tileCoords:
		var absCoord = landmark.coord + Vector2(c)
		addTileRevealedListener(landmark, absCoord)
		# landmark should be one biome, no switch in there
		tileData.set_biomev(absCoord, landmarkBiome)
		# don't have border tiles on a chamber
		tileData.set_hardnessv(absCoord, clamp(tileData.get_hardnessv(absCoord), 0, 4))
		border_deco.markTileUndecoratable(absCoord)
	
	# the chamber might have overridden the map border, so update in that case.
	for c in landmark.tileCoords:
		for neighborsOffset in NEIGHBOR_TILE_OFFSETS_DIAG:
			var landmarkCoord = Vector2(c) + neighborsOffset
			if landmark.tileCoords.has(landmarkCoord):
				continue
			
			var neighborCoord = landmark.coord + landmarkCoord
			if tileData.get_biomev(neighborCoord) < 0:
				tileData.set_biomev(neighborCoord, tileData.get_biomev(coord))
				tileData.set_resourcev(neighborCoord, Data.TILE_BORDER)
				tileData.set_hardnessv(neighborCoord, Data.HARDNESS_INDESTRUCTIBLE)
	
	if GameWorld.devMode:
		print("placed " + landmark.name + " at " + str(coord))
	tiles_node.add_child(landmark)

func revealCave(cave):
	for c in cave.tileCoords:
		var absCoord = cave.coord + c
		revealTile(absCoord)
		removeTileVisually(absCoord)

func addDrop(drop):
	add_child(drop)

func freeTiles(tileCoords:Array) -> int:
	var destroyed := 0
	for c in tileCoords:
		if tiles.has(c):
			var tile = tiles[c]
			if tile.has_meta("destructable") and Data.isDestructable(tile):
				tile.hit(Vector2(0,-1), tile.health)
				destroyed += 1
	return destroyed

func damageTileDirection(pos:Vector2, dir:Vector2i, distance:int, damage:float, delay := 0.0):
	if delay > 0.0:
		$Tween.interpolate_callback(self, delay, "damageTileDirection", pos, dir, distance, damage, 0.0)
		$Tween.start()
		return

	var startCoord = Vector2(getTileCoord(pos) + dir)
	for i in distance:
		var coord = startCoord + Vector2(dir * i)
		if tiles.has(coord):
			var tile = tiles.get(coord)
			if Data.isDestructable(tile):
				var v = coord - startCoord 
#				var dmg = damage * (1.0 - 0.9 * i / float(distance))
				tile.exploded = true
				tile.hit(v, tile.max_health + 1)
		elif is_tile_empty(coord): #in bounds and is empty cell
			Tile.spawn_tile_break_particles(self, coord, getTilePos(coord), Vector2(), "default", true, false)
		
		await get_tree().create_timer(0.08).timeout
		while GameWorld.paused:
			await get_tree().create_timer(0.08).timeout

func is_tile_empty(coord):
	return tileData.get_hardnessv(coord) > -1 and tileData.get_resourcev(coord) == -1

func damageTileCircleArea(pos:Vector2, radius:float, damage:float, delay := 0.0, offset:Vector2 = Vector2.ZERO):
	if delay > 0.0:
		$Tween.interpolate_callback(self, delay, "damageTileCircleArea", pos, radius, damage, 0.0, offset)
		$Tween.start()
		return
	
	var explosionCenterCoord = Vector2(getTileCoord(pos + offset))
	var startCoord = Vector2(getTileCoord(pos))
	prints(pos, offset, startCoord, explosionCenterCoord)
	var open := [startCoord]
	var closed := []
	while open.size() > 0:
		var newOpen := []
		for coord in open:
			if closed.has(coord):
				continue
			
			for off in NEIGHBOR_TILE_OFFSETS1:
				var c2 = off + Vector2(coord)
				if (c2 - explosionCenterCoord).length() <= radius and not closed.has(c2) and not newOpen.has(c2):
					newOpen.append(c2)
			
			if tiles.has(coord):
				var tile = tiles.get(coord)
				if Data.isDestructable(tile):
					var v = coord - explosionCenterCoord 
#					var dmg = damage * (1.0 - 0.9 * (v.length() / radius))
					tile.exploded = true
					tile.hit(v, tile.max_health + 1)
			elif is_tile_empty(coord): #in bounds and is empty cell
				Tile.spawn_tile_break_particles(self, coord, getTilePos(coord), Vector2(), "default", true, false)
			closed.append(coord)
		
		await get_tree().create_timer(0.08).timeout
		while GameWorld.paused:
			await get_tree().create_timer(0.08).timeout
		open = newOpen

func getTileCoord(pos:Vector2) -> Vector2i:
	return tileData.local_to_map(pos + mapToWorldOffset)

func getTilePos(coord:Vector2) -> Vector2:
	return tileData.map_to_local(coord) + tileData.position
	
func addMineShaftGadget(gadget):
	# TODO generify once we have multiple possible gadgets. Basic idea: one interface for shaft gadgets.
	lift = gadget
	add_child(lift)
	updateLiftLength()

func updateLiftLength():
	var goalY := 0
	var potentialTilesToConvert := []
	var tilesToConvert := []
	var lastBiome:int
	for y in tileData.getSize().y + 20:
		var hardness = tileData.get_hardness(0, y)
#		var biome = tileData.get_biome(0, y)
#		prints(y, biome, hardness, tileData.get_resource(0, y))
		if tileData.get_resource(0, y) == -1 and hardness >= 0:
			# dug out tile, lift should extend to this here
			goalY = y + 1
			lastBiome = tileData.get_biome(0, y)
			if potentialTilesToConvert.size() > 0:
				tilesToConvert = potentialTilesToConvert.duplicate()
			potentialTilesToConvert.clear()
		elif hardness >= 0 and hardness <= 4:
			# not dug out, lift should stop here
			break
		else:
			potentialTilesToConvert.append(y)
	
	for i in range(lift.tileLength, goalY):
		border_deco.markTileUndecoratable(Vector2(0,i))
		border_deco.markTileUndecoratable(Vector2(-1,i))
	lift.setLength(goalY)
	
	if tilesToConvert.size()>0:
		var t = create_tween()
		var delay := 0.5
		for y in tilesToConvert:
			t.tween_callback(createEmptyTile.bind(Vector2(0, y), lastBiome)).set_delay(delay)
			delay = 1.5

func createEmptyTile(coord:Vector2, biome):
	if tiles.has(coord):
		destroyTile(tiles.get(coord))
	else:
		tileData.set_biomev(coord, biome)
		tileData.set_hardnessv(coord, 1)
	
	buildBorderAroundTile(coord, biome)

func buildBorderAroundTile(coord, biome):
	for dir in CONST.DIRECTIONS_AND_DIAGONALS:
		var otherCoord = coord + dir
		if tiles.has(otherCoord) or tileData.get_hardnessv(otherCoord) != -1:
			continue
		tileData.set_biomev(otherCoord, biome)
		tileData.set_hardnessv(otherCoord, Data.HARDNESS_INDESTRUCTIBLE)
		tileData.set_resourcev(otherCoord, Data.TILE_BORDER)
	tileCoordsToReveal.append(coord)
	floodRevealTiles()

func getProgress() -> float:
	var layerCount = startingIronCountByLayer.size()
	if layerCount == 0:
		return 0.0

	var progress = 0.0
	for layer in startingIronCountByLayer:
		progress += 1.0 - (currentIronCountByLayer[layer] / float(startingIronCountByLayer[layer]))
	progress /= layerCount
#	progress = clamp(progress / float(Data.of("monsters.progressionIronPeak")), 0.0, 1.0)
#	progress = pow(progress, float(Data.of("monsters.progressionIronExponent")))
	return progress

func isResourceTile(typeId:int) -> bool:
	return typeId == Data.TILE_IRON or typeId == Data.TILE_SAND or typeId == Data.TILE_WATER 

func isCaveTile(coord:Vector2) -> bool:
	var res = tileData.get_resourcev(coord)
	var bio = tileData.get_biomev(coord)
	return bio >= 0 and res < 0

func isRevealed(coord:Vector2) -> bool:
	return tiles.has(coord)

func getTile(coord:Vector2):
	return tiles.get(coord, null)

func serialize()->Dictionary:
	var tileSpecial = {}
	for t in tiles.keys():
		if tiles[t].health < tiles[t].max_health or tiles[t].hasTileOverlay():
			tileSpecial[var_to_str(t)] = tiles[t].serialize()
	var data = {
		"TileSpecial": tileSpecial,
		"dropDeltas": dropDeltas,
		"Biomes": biomes,
		"StartingIronCountByLayer": startingIronCountByLayer,
		"CurrentIronCountByLayer": currentIronCountByLayer,
		"initialUsedRect": var_to_str(initialUsedRect),
		"revealedTiles" : Marshalls.raw_to_base64(var_to_bytes(tiles.keys())),
		"visuallyRevealedTiles" : Marshalls.raw_to_base64(var_to_bytes(visuallyRevealedTiles.keys()))
	}
	return data

func deserialize(data:Dictionary):
	tileDestroyedListeners = {}
	tileRevealedListeners = {}
	for child in tiles_node.get_children():
		child.free()
	
	if data.has("Biomes"):
		biomes = data["Biomes"]
	
	init(true)
	
	if data.has("revealedTiles"):
		var tilesStr = Marshalls.base64_to_raw(data["revealedTiles"])
		var tiles = bytes_to_var(tilesStr)
		tileCoordsToReveal.append_array(tiles)
	revealInitialState()
	
	if data.has("visuallyRevealedTiles"):
		var tilesStr = Marshalls.base64_to_raw(data["visuallyRevealedTiles"])
		var tiles = bytes_to_var(tilesStr)
		for x in tiles:
			revealTileVisually(x)
	
	if data.has("StartingIronCountByLayer"):
		startingIronCountByLayer = {}
		for key in data["StartingIronCountByLayer"].keys():
			startingIronCountByLayer[int(key)] = data["StartingIronCountByLayer"][key]
		
	if data.has("CurrentIronCountByLayer"):
		currentIronCountByLayer = {}
		for key in data["CurrentIronCountByLayer"].keys():
			currentIronCountByLayer[int(key)] = data["CurrentIronCountByLayer"][key]
	
	dropDeltas = data.get("dropDeltas", {})
	initialUsedRect = str_to_var(data.get("initialUsedRect", null))

	# Reveal all tiles immediately
	for t in tileCoordsToReveal:
		revealTile(t)
	tileCoordsToReveal.clear()
	
	if data.has("TileSpecial"):
		for key in data["TileSpecial"].keys():
			var t = BackwardCompatibilityUtils.str_to_var(key)
			if tiles.has(t):
				tiles[t].deserialize(data["TileSpecial"][key])

func hideTiles():
	if lift:
		lift.hide()
	
	tiles_node.hide()
	tile_borders_node.hide()
	border_deco.hide()
	$TileRender.hide()
	$BackgroundRender.hide()
	$LightSprite.hide()

func showTiles():
	if lift:
		lift.show()
	tiles_node.show()
	tile_borders_node.show()
	border_deco.show()
	$TileRender.show()
	$BackgroundRender.show()
	$LightSprite.show()

func getTileData() -> MapData:
	return tileData

func decorations():
	return border_deco

func getBiomeOfCoord(coord:Vector2) -> String:
	var b = tileData.get_biomev(coord)
	if b >= 0 and b < biomes.size():
		return biomes[b]
	else:
		return ""

func getLayerOfCoord(coord:Vector2) -> int:
	var b = tileData.get_biomev(coord)
	return b

func addSpriteToBGAlpha(_new_sprite:Sprite2D):
	var bg_alpha_pos_offset = Vector2($ViewportBackgroundAlpha.size.x/2, 48)
	var alpha_sprite_pos = _new_sprite.global_position + bg_alpha_pos_offset + mapToWorldOffset
	var alpha_sprite = _new_sprite.duplicate()
	alpha_sprite.show()
	$ViewportBackgroundAlpha/AlphaImages.add_child(alpha_sprite)
	alpha_sprite.position = alpha_sprite_pos
	$ViewportBackgroundAlpha.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	$ViewportBackgroundAlpha.render_target_update_mode = SubViewport.UPDATE_ONCE

func toggleTileDataVisibility():
	tileData.visible = !tileData.visible

@onready var viewportTopEffectsAnchor = $"%ViewportTopEffectsAnchor"
func addPixelEffect(node:Node2D):
	viewportTopEffectsAnchor.add_child(node)

func registerAdditionalEffect(effect):
	$AdditionalEffects.add_child(effect)

func getAdditionalEffects() -> Array:
	return $AdditionalEffects.get_children()

func isWithinBounds(coord) -> bool:
	if coord.y < 0:
		return false
	if coord.x <= initialUsedRect.position.x or coord.x >= initialUsedRect.end.x:
		return false
	if coord.y >= initialUsedRect.end.y:
		return false
	return true
