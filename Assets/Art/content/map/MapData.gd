extends TileMap

# renamed from TileData to MapData due to name clash with build in class
class_name MapData

const DEFAULT_LAYER = 0
const LAYER_BIOME = 0
const LAYER_HARDNESS = 1
const LAYER_RESOURCES = 2

func get_biome(x:int, y:int) -> int:
	return get_biomev(Vector2i(x, y))

func get_biomev(coord:Vector2i) -> int:
	var atlas_coord:Vector2i = get_cell_atlas_coords(LAYER_BIOME, coord)
	return max(-1, atlas_coord.x + (atlas_coord.y - 3) * 10)

func set_biomev(coord:Vector2i, val:int):
	if val < 0:
		set_cell(LAYER_BIOME, coord, -1)
	else:
		set_cell(LAYER_BIOME, coord, 0, Vector2i(val % 10, 3 + val / 10))

func get_hardness(x:int, y:int) -> int:
	return get_hardnessv(Vector2i(x, y))

func get_hardnessv(coord:Vector2) -> int:
	var atlas_coord:Vector2i = get_cell_atlas_coords(LAYER_HARDNESS, coord)
	return max(-1, atlas_coord.x + (atlas_coord.y - 2) * 10)

func set_hardnessv(coord:Vector2, val:int):
	if val < 0:
		set_cell(LAYER_HARDNESS, coord, -1)
	else:
		set_cell(LAYER_HARDNESS, coord, 0, Vector2i(val % 10, 2 + val / 10))

func get_resource(x:int, y:int) -> int:
	return get_resourcev(Vector2(x, y))

func get_resourcev(coord:Vector2) -> int:
	var atlas_coord:Vector2i = get_cell_atlas_coords(LAYER_RESOURCES, coord)
	return max(-1, atlas_coord.x + atlas_coord.y * 10)

func set_resourcev(coord:Vector2, val:int):
	if val < 0:
		set_cell(LAYER_RESOURCES, coord, -1)
	else:
		set_cell(LAYER_RESOURCES, coord, 0, Vector2i(val % 10, val / 10))

func is_area_free(start:Vector2, offsets:Array) -> bool:
	for c in offsets:
		var absCoord = start + c
		if get_resourcev(absCoord) != 10:
			return false
	return true

func clear_resource(coord:Vector2):
	set_cell(LAYER_RESOURCES, coord, -1)

func clear():
	clear()

func getRevealedCells() -> Array:
	var cells := []
	for cell in get_used_cells(LAYER_HARDNESS):
		if get_resourcev(cell) < 0:
			cells.append(cell)
	return cells

func get_used_biome_cells() -> Array:
	return get_used_cells(LAYER_BIOME)
	
func get_used_hardness_cells() -> Array:
	return get_used_cells(LAYER_HARDNESS)

func get_used_resource_cells() -> Array:
	return get_used_cells(LAYER_RESOURCES)

func get_biome_cells_by_index(index:int) -> Array:
	var val := 30 + index
	return get_used_cells_by_id(LAYER_BIOME, 0, Vector2i(val % 10, val / 10))
	
func get_resource_cells_by_id(id:int) -> Array:
	return get_used_cells_by_id(LAYER_RESOURCES, 0, Vector2i(id % 10, id / 10))

func get_hardness_cells_by_grade(grade:int) -> Array:
	var val := 20 + grade
	return get_used_cells_by_id(LAYER_HARDNESS, 0, Vector2i(val % 10, val / 10))

func get_mineable_tile_count() -> int:
	var all = get_used_cells(LAYER_BIOME).size()
	return all - get_hardness_cells_by_grade(5).size()

func get_remaining_mineable_tile_count() -> int:
	var all = get_used_cells(LAYER_RESOURCES).size()
	return all - get_resource_cells_by_id(19).size()

func get_mineable_tile_coords() -> Array:
	var coords := []
	coords.append_array(get_resource_cells_by_id(Data.TILE_IRON))
	coords.append_array(get_resource_cells_by_id(Data.TILE_WATER))
	coords.append_array(get_resource_cells_by_id(Data.TILE_SAND))
	coords.append_array(get_resource_cells_by_id(Data.TILE_GADGET))
	coords.append_array(get_resource_cells_by_id(Data.TILE_RELIC))
	coords.append_array(get_resource_cells_by_id(Data.TILE_RELIC_SWITCH))
	coords.append_array(get_resource_cells_by_id(Data.TILE_SUPPLEMENT))
	coords.append_array(get_resource_cells_by_id(Data.TILE_DIRT_START))
	return coords

func getSize() -> Vector2:
	return get_used_rect().size

func getMaxSize() -> Vector2:
	var resource_rect:Rect2 = get_used_rect()
	var x = max(abs(resource_rect.position.x), resource_rect.size.x - abs(resource_rect.position.x))
	var padding = Vector2(2,2)
	return Vector2(x * 2, resource_rect.size.y) + padding

func getMapSizePx() -> Vector2:
	return -get_used_rect().position + get_used_rect().size * GameWorld.TILE_SIZE

#func local_to_map(pos:Vector2) -> Vector2:
	#return local_to_map(pos)
#
#func map_to_local(pos:Vector2) -> Vector2:
	#return map_to_local(pos)

func pack() -> PackedScene:
	for c in get_children():
		c.set_owner(self)
	visible = true
	var packed_scene = PackedScene.new()
	packed_scene.pack(self)
	visible = false
	return packed_scene

func stack(tileData:MapData, coordinateOffset := Vector2()):
	var coordOffset = Vector2i(coordinateOffset)
	for coord in tileData.get_used_cells(LAYER_BIOME):
		set_biomev(coord + coordOffset, tileData.get_biomev(coord))
	for coord in tileData.get_used_cells(LAYER_HARDNESS):
		set_hardnessv(coord + coordOffset, tileData.get_hardnessv(coord))
	for coord in tileData.get_used_cells(LAYER_RESOURCES):
		set_resourcev(coord + coordOffset, tileData.get_resourcev(coord))
	
	# option to remove tiles
	for coord in get_used_cells(LAYER_RESOURCES):
		if tileData.get_resourcev(Vector2(coord) - coordinateOffset) == -1 and tileData.get_biomev(Vector2(coord) - coordinateOffset) != -1:
			clear_resource(coord)
