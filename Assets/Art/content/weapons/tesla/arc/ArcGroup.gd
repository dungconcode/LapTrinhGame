extends Node2D
class_name TeslaArc

const Arc = preload("res://content/weapons/tesla/arc/Arc.tscn")
const ARCING := 70.0
const INTERVAL := 30.0
const ARC_FACTOR := 200.0

@export var lightColor := Color("#78ff00")
@export var darkColor := Color("#083500")
@export var darkColorAlpha := 1.0

@export var spawnSparksAtImpact := false
@export var onlyManualSpawn := false
@export var forkSpawnArea := Vector2(0, 20)
@export var arcTtlFactor := 1.0
@export var spawnInterval := 0.2
@export var randomInterval := 0.7
@export var baseCurvature := 1.0
@export var arcIntensity := 1.0
@export var randomCurvature := 0.3
@export var showEndFork := true
@export var arcWildness := 70.0
@export var impactRadius := 6.0

var extraPower := 1.0
var styledLightColor := Color("#78ff00")
var styledDarkColor := Color("#083500")

var curvature := 0.0
var time := 0.0
var bendTime := 0.0
var target : Vector2 = Vector2.ZERO

func _ready():
	Style.init(self)

func updateStyleColor():
	styledLightColor = Style.mapColor(lightColor)
	styledDarkColor = Style.mapColor(darkColor)

func createArc(pos:Vector2, tar:Vector2, fork:=false):
	var newArc = Arc.instantiate()
	var p : Array = [Vector2.ZERO]
	var length : float = pos.distance_to(tar)
	var radius = length*0.5
	var dir : Vector2 = Vector2.RIGHT
	var count : int = max(floor(length/INTERVAL), 5)
	var segLength := minf(length/count, INTERVAL)
	var arcFactor = min(length/ARC_FACTOR*arcIntensity*40.0 * randf(), ARCING)
	var arcRand := randf()+1.0
	var arcRandOffset : float = arcWildness * clamp((length-20.0)/max(arcWildness, 0.1), 0.0, 1.0)
	var rot : float = pos.direction_to(tar).angle()
	
	if fork:
		arcFactor *= -1.5
		arcRand *= 0.5
	
	var curvMod := Vector2.ZERO
	for i in count-1:
		var seg : Vector2 = (dir*(i+1)*segLength)
		var bent : float = sin(bendTime*4.0 + remap((i+1)*0.5*randf_range(1.2, 1.5), 0, count, 0, TAU*arcRand))*arcFactor
		if not fork:
			var x = remap(float(i+1), 0, (count), 0, length)
			var y = sqrt(radius * radius - pow(x - radius, 2))
			curvMod = Vector2(0, y*(curvature+baseCurvature))
		var segment : Vector2 = seg + curvMod + Vector2(0, bent + (randf()-0.5)*arcRandOffset)
		p.append(segment)
	
	if not fork:
		for i in (randi()%2)+1:
			var forkPoint : int = max(randi()%int(floor(count/1.5)), 3)
			if randf() > 0.3:
				createArc(pos+(forkSpawnArea*randf_range(-1, 1)).rotated(rot), pos+(p[forkPoint]).rotated(rot), true)
			if showEndFork and randf() > 0.3:
				createArc(tar, pos+(p[-forkPoint]).rotated(rot), true)
				
		if spawnSparksAtImpact:
			var sparks = preload("res://content/weapons/tesla/OrbImpactSparks.tscn").instantiate()
			sparks.position = pos+(Vector2.RIGHT*length).rotated(rot)
			Level.map.addPixelEffect(sparks)
	
	# Make target point
	p.append(Vector2.RIGHT*length)
	
	newArc.alphaMod = modulate.a
	newArc.ttlFactor = arcTtlFactor
	newArc.fork = fork
	newArc.points = p
	newArc.rotation = rot
	newArc.position = pos
	newArc.lightColor = styledLightColor*extraPower
	newArc.lightColor.a = min(newArc.lightColor.a, 1.0)
	newArc.darkColor = styledDarkColor*extraPower
	newArc.darkColor.a = min(newArc.darkColor.a, 1.0)
	newArc.darkColorMod = darkColorAlpha
	Level.map.addPixelEffect(newArc)

var timer := randf()
func _process(delta:float):
	if not is_visible_in_tree():
		return
	time = wrapf(time+delta*10.0, 0.0, 1.0)
	bendTime = wrapf(bendTime+delta, 0.0, 1.0)
	if onlyManualSpawn:
		return
	timer += delta
	if timer >= spawnInterval:
		timer = randf()*spawnInterval*0.3
		if randf()>(randomInterval-time):
			curvature = randf_range(-randomCurvature, randomCurvature)
			createArc(global_position, target+Vector2.RIGHT.rotated(randf()*TAU)*impactRadius)


func forceCreateArc():
	curvature = randf_range(-randomCurvature, randomCurvature)
	createArc(global_position, target+Vector2.RIGHT.rotated(randf()*TAU)*impactRadius)
