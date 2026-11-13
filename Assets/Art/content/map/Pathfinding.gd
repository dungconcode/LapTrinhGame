extends RefCounted
class_name Pathfinding

var pathfinder:AStar2D
var pointIdsByCoord := {} # pathfinder point id's by tile coord

func _init():
	pathfinder = AStar2D.new()

func findPath(from:Vector2, to:Vector2):
	if not pointIdsByCoord.has(from):
		return null
	if not pointIdsByCoord.has(to):
		Logger.warn("cannot find path as destination coord is not within pathfinding map", "Map.findPath", {"fromPos":from, "toPos":to})
		return null
	
	return pathfinder.get_point_path(pointIdsByCoord[from], pointIdsByCoord[to])

func cleanup():
	pointIdsByCoord.clear()

func add_point_in_coord(pos):
	pos = pos * GameWorld.TILE_SIZE + CONST.TILE_OFFSET
	var id = pathfinder.get_available_point_id()
	pointIdsByCoord[pos] = id
	pathfinder.add_point(id, pos)

func try_connect_coord(source,dest):
	source = source * GameWorld.TILE_SIZE + CONST.TILE_OFFSET
	dest = dest * GameWorld.TILE_SIZE + CONST.TILE_OFFSET
	if pointIdsByCoord.has(dest) and pointIdsByCoord.has(source):
		pathfinder.connect_points(pointIdsByCoord[source], pointIdsByCoord[dest], true)
