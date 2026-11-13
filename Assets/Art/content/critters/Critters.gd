extends Node

# Critters
const PROBABILITY_roach = 0.4
const MAXAMOUNT_roach = 20
const PROBABILITY_eyes = 0.5
const MAXAMOUNT_eyes = 8
const PROBABILITY_worm = 0.2
const MAXAMOUNT_worm = 3
const PROBABILITY_rat = 0.15
const MAXAMOUNT_rat = 2
const PROBABILITY_shroomer = 0.2
const MAXAMOUNT_shroomer = 4

const CRITTER_MIN_DISTANCE = 50
const EYE_MAX_DISTANCE_TO_RESOURCE = 30

var critterByBiome := {
	"green": ["shroomer"],
	"red": ["roach", "eyes"],
	"yellow": ["rat", "eyes"],
	"blue": ["worm"],
}

const COORD_ABOVE = Vector2(0, -1)

func _on_Timer_timeout():
	if Options.disableCritters:
		return
	
	if Keepers.allInsideDome():
		return
	
	for keeper in Keepers.getAll():
		var keeperCoord = Level.map.getTileCoord(keeper.global_position)
		var tilesByBiome := {}
		for x in range(-10, 10):
			for y in range(-8, 8):
				if abs(x) <= 3 and abs(y) <= 3:
					continue
				var offset = Vector2i(x, y)
				var coord = keeperCoord + offset
				if coord.y < 3:
					continue
				var t = Level.map.getTile(coord)
				if t and t.type:
					var tiles
					if tilesByBiome.has(t.biome):
						tiles = tilesByBiome.get(t.biome)
					else:
						tiles = []
						tilesByBiome[t.biome] = tiles
					tiles.append(t)
		var dropsNearKeeper = getDropsNearKeeper()
	
		var closeBiomes := []
		for offsetY in [-4,0,4]:
			var biome = Level.map.getBiomeOfCoord(keeperCoord + Vector2i(0, offsetY))
			if biome and not closeBiomes.has(biome):
				closeBiomes.append(biome)

		for biome in closeBiomes:
			for critter in critterByBiome.get(biome, []):
				if randf() <= get("PROBABILITY_" + critter):
					var critters = get_tree().get_nodes_in_group("critters_" + critter)
					if critters.size() < get("MAXAMOUNT_" + critter):
						call("spawn_" + critter, tilesByBiome.get(biome, []), critters, dropsNearKeeper)


# Eyes appear and disappear randomly in unrevealed tiles
#
# These spawn near drops with a probability that varies
# based on the number of drops near the keeper. They appear
# with a much higher probability as the relic is being brought
# to the surface. They disappear as the keeper approaches.
func spawn_eyes(tiles:Array, critters:Array, dropsNearKeeper:Array):
	for drop in dropsNearKeeper:
		if randf() > 0.2:
			# don't engage with every single resource
			continue
		
		var skip = false
		for e in critters:
			if e.global_position.distance_to(drop.global_position) < CRITTER_MIN_DISTANCE:
				# already getting eyeballed
				skip = true
		if skip: 
			continue
		
		var Critter = preload("res://content/critters/eyes/CaveCritterEyes.tscn")
		var tileCoord = Level.map.getTileCoord(drop.global_position)
		var randDir : Array = CONST.DIRECTIONS.duplicate()
		randDir.shuffle()
		for offset in randDir:
			var tile = Level.map.getTile(tileCoord + Vector2i(offset))
			if tile and tiles.has(tile):
				var critter = Critter.instantiate()
				critter.tile = tile
				add_child(critter)
				critter.global_position = tile.global_position + Vector2(randf_range(0, 8), 0).rotated(randf() * TAU)
				break

# Spawn roaches near drops
#
# Similar to eyes, these appear with a probability that varies
# based on the number of drops near the keeper. But the probability
# increases significantly when there are other roaches nearby which
# occassionaly creates roach swarms. They scatter as the keeper
# approaches.
func spawn_roach(tiles:Array, critters:Array, dropsNearKeeper:Array):
	for d in dropsNearKeeper:
		if randf() > 0.4:
			# don't engage with every single resource
			continue
		var tileCoord = Level.map.getTileCoord(d.global_position)
		var tile = null
		var offsets = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
		offsets.shuffle()
		for offset in offsets:
			tile = Level.map.getTile(tileCoord + offset)
			if tile and tiles.has(tile):
				var critter = preload("res://content/critters/roach/Roach.tscn").instantiate()
				add_child(critter)
				critter.global_position = tile.global_position + Vector2(randf_range(0, 8), 0).rotated(randf() * TAU)
				critter.goto(d)

# Spawn worms near the keeper
#
# These spawn anywhere near where the keeper is working.
# They come outward from a wall then draw themselves back in after
# a short time. They retract as the keeper approaches.
func spawn_worm(tiles:Array, critters:Array, dropsNearKeeper:Array):
	tiles.shuffle()
	var randDir : Array = CONST.DIRECTIONS.duplicate()
	randDir.shuffle()
	for offset in randDir:
		var tile = getFreeTile(tiles, offset)
		if tile:
			var critter = preload("res://content/critters/worm/Worm.tscn").instantiate()
			critter.tile = tile
			add_child(critter)
			critter.global_position = tile.global_position + offset * GameWorld.TILE_SIZE * 0.93
			critter.global_position += Vector2(randf_range(-8, 8),0).rotated(offset.angle() + PI/2)
			critter.global_rotation = offset.angle()
			return

# Spawn rats near the keeper
#
# These spawn on any floor tile near where keeper is working.
# They roam the tunnels and scatter as the keeper approaches.
func spawn_rat(tiles:Array, critters:Array, dropsNearKeeper:Array):
	tiles.shuffle()
	var tile = getFreeTile(tiles, COORD_ABOVE)
	if tile:
		var critter = preload("res://content/critters/rat/Rat.tscn").instantiate()
		add_child(critter)
		critter.global_position = tile.global_position + COORD_ABOVE * GameWorld.TILE_SIZE

func spawn_shroomer(tiles:Array, critters:Array, dropsNearKeeper:Array):
	tiles.shuffle()
	var tile = getFreeTile(tiles, COORD_ABOVE)
	if tile:
		var critter = preload("res://content/critters/mushroomman/Shroomer.tscn").instantiate()
		add_child(critter)
		critter.start(tile)
		critter.global_position = tile.global_position + COORD_ABOVE * GameWorld.TILE_SIZE * 0.45

# Get drops near the keeper
func getDropsNearKeeper():
	var drops = get_tree().get_nodes_in_group("drops")
	var selectedDrops := []
	for i in range(drops.size()-1, -1, -1):
		var d = drops[i]
		for keeper in Keepers.getAll():
			var distance_from_keeper = keeper.global_position.distance_to(d.global_position)
			if distance_from_keeper > CRITTER_MIN_DISTANCE and distance_from_keeper <= 250:
				selectedDrops.append(d)
	selectedDrops.shuffle()
	return selectedDrops

func getFreeTile(tiles:Array, offset:Vector2):
	for tile in tiles:
		var biome = Level.map.getBiomeOfCoord(tile.coord + offset)
		var resource = Level.map.tileData.get_resourcev(tile.coord + offset)
		var hardness = Level.map.tileData.get_hardnessv(tile.coord + offset)
		if biome and resource == -1 and hardness >= 0:
			return tile
	return null

func pauseChanged():
	if GameWorld.paused:
		$Timer.paused = true
	else:
		$Timer.paused = false
