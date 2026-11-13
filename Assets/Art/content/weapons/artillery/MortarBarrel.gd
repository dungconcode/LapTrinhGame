extends Node2D

const EmptyShell := preload("res://content/weapons/artillery/MortarShellEmpty.tscn")

var recoilAmount := [4.0, 7.0, 5.0, 6.0, 7.0, 4.0]
var multiShot := false

@onready var barrels := [$Upgrade0, $Upgrade1, $Upgrade2, $Upgrade3, $Upgrade4, $Upgrade5]
@onready var barrelTops := [$Upgrade0/CannonBot/CannonTop,
						$Upgrade1/CannonBot/CannonTop,
						$Upgrade2/CannonBot/CannonTop,
						$Upgrade3/CannonBot/CannonTop,
						$Upgrade4/CannonBot/CannonTop,
						$Upgrade5/CannonBot/CannonTop
						]
@onready var barrelBottoms := [$Upgrade0/CannonBot, $Upgrade1/CannonBot, $Upgrade2/CannonBot, $Upgrade3/CannonBot, $Upgrade4/CannonBot, $Upgrade5/CannonBot]
@onready var tween = $Tween

func setBarrelSize(index:int=0):
	for b in barrels:
		b.hide()
	barrels[index].show()
	$Base.position.y = 0.0

func getSpawnPoint():
	for b in barrels:
		if b.visible:
			return b.get_node("SpawnPoint")

func shoot(reloadTime:float, isMultiShot:=false):
	var smoke = preload("res://content/weapons/artillery/MortarMuzzleSmoke.tscn").instantiate()
	smoke.position = getSpawnPoint().global_position
	smoke.rotation = global_rotation
	Level.map.addPixelEffect(smoke)
	var barrelSet = getBarrelSet()
	var recoilY = barrelSet[2]
	var barrelTop = barrelSet[0]
	var barrelBottom = barrelSet[1]
	var inDuration := 0.1
	var outDuration = min(reloadTime - inDuration, 0.4)
	var _delay = inDuration + max(0, reloadTime - outDuration)
	tween.remove_all()
	tween.interpolate_property(barrelTop, "position:y", 0, recoilY, 0.04, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.interpolate_property(barrelBottom, "position:y", 0, recoilY*1.5, 0.2, Tween.TRANS_BOUNCE, Tween.EASE_OUT, 0.06)
	tween.interpolate_property($Base, "position:y", 0, recoilY, 0.2, Tween.TRANS_BOUNCE, Tween.EASE_OUT, 0.06)
	
	if isMultiShot:
		var rightEject : bool = global_rotation < 0
		var opening = $Base/BaseRotR if rightEject else $Base/BaseRotL
		var angle = -60 if rightEject else 60
		if opening.rotation != 0:
			opening.rotation_degrees = angle * 0.8
		tween.interpolate_property(opening, "rotation_degrees", opening.rotation_degrees, angle, 0.2, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		tween.interpolate_callback(self, 0.02, "ejectShell", rightEject)
	else:
		$Base/BaseRotR.rotation = 0
		$Base/BaseRotL.rotation = 0
	tween.start()

func getBarrelSet() -> Array:
	var barrelIndex : int = -1
	for i in barrels.size():
		if barrels[i].visible:
			barrelIndex = i
	var barrelRecoil = recoilAmount[barrelIndex]
	var barrelTop = barrelTops[barrelIndex]
	var barrelBottom = barrelBottoms[barrelIndex]
	return [barrelTop, barrelBottom, barrelRecoil]

func reloadComplete():
	var barrelSet = getBarrelSet()
	var barrelTop = barrelSet[0]
	var barrelBottom = barrelSet[1]
	tween.remove_all()
	tween.interpolate_property(barrelTop, "position:y", barrelTop.position.y, 0, 0.2, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	tween.interpolate_property(barrelBottom, "position:y", barrelBottom.position.y, 0, 0.2, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	tween.interpolate_property($Base, "position:y", $Base.position.y, 0, 0.2, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	
	var rightEject : bool = global_rotation < 0
	var opening = $Base/BaseRotR if rightEject else $Base/BaseRotL
	var angle = -60 if rightEject else 60
	var delay := 0.0
	if Data.of("artillery.grenades") <= 1:
		tween.interpolate_property(opening, "rotation_degrees", 0, angle, 0.2, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
		ejectShell(rightEject)
		delay = 0.35
	tween.interpolate_property($Base/BaseRotR, "rotation_degrees", $Base/BaseRotR.rotation_degrees, 0, 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT, delay)
	tween.interpolate_property($Base/BaseRotL, "rotation_degrees", $Base/BaseRotL.rotation_degrees, 0, 0.1, Tween.TRANS_EXPO, Tween.EASE_OUT, delay)
	tween.start()

func ejectShell(isRight:=false):
	var emptyShell = EmptyShell.instantiate()
	emptyShell.position = $Base/ShellEjectPosR.global_position if isRight else $Base/ShellEjectPosL.global_position
	var impulse = 200 if isRight else -200
	var initialImpulse : Vector2 = Vector2(impulse, 120.0).rotated(global_rotation)*randf_range(0.7, 1.1)
	emptyShell.initialImpulse = initialImpulse
	Level.map.add_child(emptyShell)

func pauseChanged():
	if GameWorld.paused:
		tween.stop_all()
	else:
		tween.resume_all()
