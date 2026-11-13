extends Path2D

@export var smoothness : float = 6
@export var curveBias : float = 0.5
@export var skipFactor : float = 0.8
@export var inbetweenStrength : float = 0.3

var startPoint : Vector2 = Vector2.ZERO
var endPoint : Vector2 = Vector2.RIGHT
var bakedPoints := []
var bakedLength := 0.0
var bakedSegmentLength := 0.0
var lines := []

func _ready():
	createLine(startPoint, endPoint)
	createLineSegments()
	StageManager.connect("stage_started", Callable(self, "checkCableOverlap"))

func activate():
	for l in lines:
		l.activate()

func deactivate():
	for l in lines:
		l.deactivate()


func createLineSegments():
	var currentOffset := 0.0
	var amount : int = round(randf_range(6, 9))
	var startSegment := []
	if bakedPoints.size() > amount:
		for i in amount:
			startSegment.append(bakedPoints.pop_front())
		createSegment(startSegment, currentOffset, amount*bakedSegmentLength)
		
	currentOffset += amount*bakedSegmentLength
	
	while not bakedPoints.is_empty():
		var skipAmount = clamp(round(ease(randf_range(0.2, 1.0), skipFactor)*11), 6, 11)
		skipAmount = min(skipAmount, max(bakedPoints.size()-17, 2))
		if bakedPoints.size() > skipAmount:
			for i in skipAmount:
				bakedPoints.pop_front()
		else:
			bakedPoints.clear()
		currentOffset += skipAmount*bakedSegmentLength
		
		if bakedPoints.size() < 20:
			createSegment(bakedPoints, currentOffset, bakedPoints.size()*bakedSegmentLength)
			bakedPoints.clear()
			continue
		
		var segAmount := roundf( max(ease(randf_range(0.2, 1.0), 0.8)*8, 6) )
		if bakedPoints.size() > segAmount:
			var nextSeg := []
			for i in segAmount:
				nextSeg.append(bakedPoints.pop_front())
			createSegment(nextSeg, currentOffset, segAmount*bakedSegmentLength)
		else:
			bakedPoints.clear()
		currentOffset += segAmount*bakedSegmentLength


func createSegment(segmentPoints:Array, offset:float, length:float):
	var newSegment = preload("res://content/map/chamber/relicswitch/NewCable/CableSegment.tscn").instantiate()
	newSegment.points = segmentPoints
	newSegment.cableOffset = offset
	newSegment.cableTotalLength = length
	add_child(newSegment)
	lines.append(newSegment)
	
	var newShadowSegment = preload("res://content/map/chamber/relicswitch/NewCable/CableSegment.tscn").instantiate()
	newShadowSegment.points = segmentPoints
	newShadowSegment.cableOffset = offset
	newShadowSegment.cableTotalLength = length
	newShadowSegment.isShadow = true
	add_child(newShadowSegment)
	lines.append(newShadowSegment)


func createLine(start:Vector2, end:Vector2):
	var newPoints := []
	var cableDir = start.direction_to(end).angle()
	var cableDist = max(start.distance_to(end) / float(24), 3.0)
	newPoints.append(start)
	var randSinMulti := -1.0 if randi()%2==0 else 1.0
	var randSinAmp := randf_range(0.8, 1.2)
	var curvePower := 0.45
	for i in round(cableDist)-2:
		var newPos : Vector2 = lerp(start, end, remap(i+1, 0, cableDist, 0, 1))
		newPos += Vector2.UP.rotated(cableDir)*sin(wrapf(float(i)*randSinAmp, 0, TAU))*(15.0*randSinMulti*curvePower)
		newPos = lerp(newPos, newPos.snapped(Vector2(24, 24)), 0.3)
		newPos += Vector2(randf_range(-6, 6), 12 + randf_range(-6, 6)) * curvePower
		newPoints.append(newPos)
	newPoints.append(end)
	bakeLine(newPoints)


func bakeLine(newPoints:Array):
	curve.clear_points()
	for i in newPoints.size():
		var newPoint = newPoints[i]
		if i > 0:
			var lastPoint = newPoints[i-1]
			var inbetween = lerp(lastPoint, newPoint, 0.5)
			inbetween += Vector2.RIGHT.rotated(randf()*TAU)*lastPoint.distance_to(newPoint)*inbetweenStrength
			curve.add_point(inbetween)
		curve.add_point(newPoints[i])
	
	for i in range(1, curve.get_point_count()-1):
		var a = curve.get_point_position(i-1)
		var b = curve.get_point_position(i)
		var c = curve.get_point_position(i+1)
		
		var direction_a = a.direction_to(b)
		var direction_b = b.direction_to(c)
		var tangent_direction = direction_a.slerp(direction_b, curveBias)

		curve.set_point_in(i, tangent_direction * -smoothness)
		curve.set_point_out(i, tangent_direction  * smoothness)
	
	bakedPoints = curve.get_baked_points()
	bakedLength = curve.get_baked_length()
	bakedSegmentLength = bakedLength / bakedPoints.size()


func checkCableOverlap():
	if not Level.map:
		return
	var markedForCleanup := []
	for l in lines:
		if (Level.map.tileData.get_resourcev(Level.map.getTileCoord(l.points[0])) == Data.TILE_CAVE or
		Level.map.tileData.get_resourcev(Level.map.getTileCoord(l.points[-1])) == Data.TILE_CAVE):
			markedForCleanup.append(l)
	for m in markedForCleanup:
		lines.erase(m)
		m.queue_free()
