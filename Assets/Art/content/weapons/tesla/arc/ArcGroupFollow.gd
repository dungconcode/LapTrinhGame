extends Node2D

@export var lightColor := Color("#78ff00")
@export var darkColor := Color("#083500")
@export var darkColorAlpha := 1.0

const ArcFollow = preload("res://content/weapons/tesla/arc/ArcFollow.tscn")
const ARCING := 70.0
const ARC_FACTOR := 200.0

@export var arcMat : Material = null

@export var useGlobalPos := true
@export var timeBaseSpawn := false
@export var lengthBasedSpawnThreshold := 8
@export var maxPoints := 30
@export var interval := 20.0
@export var pointDieSpeed := 0.05
@export var spawnArea := Vector2(3, 3)
@export var arcTtlFactor := 1.0
@export var spawnInterval := 0.2
@export var randomInterval := 0.7
@export var arcIntensity := 2.0
@export var arcWildness := 30.0

var extraPower := 1.0
var styledLightColor := Color("#78ff00")
var styledDarkColor := Color("#083500")

var time := 0.0
var bendTime := 0.0
var target : Vector2 = Vector2.ZERO
var targetHistory := []

func _ready():
	Style.init(self)

func updateStyleColor():
	styledLightColor = Style.mapColor(lightColor)
	styledDarkColor = Style.mapColor(darkColor)

func createArc(hPos:Array, fork:=false):
	var positions = hPos.duplicate()
	var newArc = ArcFollow.instantiate()
	var length : float = positions[0].distance_to(positions[-1])
	var arcFactor = min(length/ARC_FACTOR*arcIntensity*40.0 * randf(), ARCING)
	var arcRand := randf()+1.0
	var arcRandOffset : float = arcWildness * clamp((length-10.0)/max(arcWildness, 0.1), 0.0, 1.0)
	var s : float = float(positions.size())
	
	if fork:
		arcFactor *= -1.2
		arcRand *= 0.5
		arcRandOffset *= 2.0
	
	for i in positions.size()-1:
		var bent : float = sin(bendTime*4.0 + remap((i+1)*0.5*randf_range(1.2, 1.5), 0, s, 0, TAU*arcRand))*arcFactor
		bent *= sin( (float(i+1)/(s-1.0))*PI)
		var dir : float = hPos[i].direction_to(hPos[i+1]).angle()
		positions[i+1] += Vector2(0.0, bent + (randf()-0.5) * arcRandOffset).rotated(dir)
	
	if not fork:
		for i in (randi()%2)+1:
			if randf() > 0.3:
				var p := []
				var offset := Vector2(0.0, randf_range(-0.1, 1.0)*20.0*sign(randf()-0.5)).rotated(positions[0].direction_to(positions[-1]).angle())
				var fork_s := int(float(s)*randf_range(0.4, 0.8))
				for pos in int(fork_s):
					p.append( positions[pos] + (offset * sin((float(pos)/fork_s)*TAU)))
				createArc(p, true)
	
	newArc.alphaMod = modulate.a
	newArc.ttlFactor = arcTtlFactor
	newArc.fork = fork
	newArc.points = positions
	newArc.lightColor = styledLightColor*extraPower
	newArc.lightColor.a = min(newArc.lightColor.a, 1.0)
	newArc.darkColor = styledDarkColor*extraPower
	newArc.darkColor.a = min(newArc.darkColor.a, 1.0)
	newArc.darkColorMod = darkColorAlpha
	if arcMat != null:
		newArc.material = preload("res://content/weapons/tesla/arc/ArcFollowSmoothMaterial.tres")
	Level.map.addPixelEffect(newArc)

var timer := randf()
var point_remove_timer := 0.0
func _process(delta:float):
	if not is_visible_in_tree():
		return
	
	target = global_position if useGlobalPos else position
	
	if targetHistory.is_empty():
		targetHistory.append(target)
	else:
		if target.distance_to(targetHistory[0]) > interval:
			targetHistory.push_front(target+spawnArea.rotated(randf()*TAU))
	if targetHistory.size() > maxPoints:
		targetHistory.pop_back()
	
	time = wrapf(time+delta*10.0, 0.0, 1.0)
	bendTime = wrapf(bendTime+delta, 0.0, 1.0)
	timer += delta
	if targetHistory.size() > lengthBasedSpawnThreshold:
		if timeBaseSpawn and timer >= spawnInterval:
			timer = randf()*spawnInterval*0.3
			if randf()>(randomInterval-time):
				doSpawn(randf_range(0.3, 0.8))
		else:
			doSpawn(randf_range(0.7, 0.9))
			
	point_remove_timer += delta
	if !targetHistory.is_empty() and point_remove_timer > pointDieSpeed:
		point_remove_timer = 0.0
		targetHistory.pop_back()

func doSpawn(shrink:float):
	createArc(targetHistory)
	targetHistory.resize(targetHistory.size()*shrink)


func _on_ArcGroupFollow_visibility_changed():
	if visible:
		targetHistory.clear()
