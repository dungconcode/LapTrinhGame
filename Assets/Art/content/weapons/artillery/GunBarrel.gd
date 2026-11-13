extends Node2D

const Bullet := preload("res://content/weapons/artillery/Bullet.tscn")
const EmptyShell := preload("res://content/weapons/artillery/FlakShellEmpty.tscn")

@export var flip_h := false

var recoilAmount := [4.0, 5.0, 3.0, 2.0, 1.0, 1.0, 1.0]
var gunCooldown:float
var soundsDefaultVol := []
var fastFireVolume := 0.0

@onready var barrels := [$Upgrade0, $Upgrade1, $Upgrade2, $Upgrade3, $Upgrade4, $Upgrade5, $Upgrade6]
@onready var barrelTops := [$Upgrade0/Bottom/Top,
							$Upgrade1/Bottom/Top,
							$Upgrade2/Bottom/Top,
							$Upgrade3/Bottom/Top,
							$Upgrade4/Bottom/Top,
							$Upgrade5/Bottom/Top,
							$Upgrade6/Bottom/Top]
@onready var tween = $Tween
@onready var sounds := [$MachineGunFire, $HomingRocket, $HomingRocket2]

func _ready():
	for b in barrels:
		if b.visible:
			b.scale.x = 1 if not flip_h else -1
	for s in sounds:
		soundsDefaultVol.append(s.volume_db)


func setBarrelSize(index:int=0):
	for b in barrels:
		b.hide()
	barrels[index].show()
	barrels[index].scale.x = 1 if not flip_h else -1

func getSpawnPoint():
	for b in barrels:
		if b.visible:
			return b.get_node("SpawnPoint")

func proc(delta:float, gunPressedValue:float, delay:float = 0.0) -> float:
	if delay > 0.0:
		gunCooldown = delay
	if gunCooldown > 0:
		gunCooldown -= delta
	
	if gunCooldown <= 0.0 and gunPressedValue > 0.0:
		fireGunBullet()
		fastFireVolume = clamp(fastFireVolume+delta*36.0, 0.0, 6.0)
		return gunCooldown
	
	if gunPressedValue <= 0.0:
		fastFireVolume = 0.0
	
	return 0.0

func fireGunBullet():
	InputSystem.shake(20, 0.4, 10, global_position)
	var shell = Bullet.instantiate()
	shell.rotation = global_rotation + randf_range(-0.03, 0.03)
	shell.position = getSpawnPoint().global_position
	if not Data.of("artillery.machinegunhoming"):
		ejectShell(flip_h)
	Level.map.add_child(shell)
	shell.fire(Data.of("artillery.machinegunbulletspeed"))
	gunCooldown = Data.of("artillery.machinegunreloadspeed")
	
	var sound = sounds[int(Data.of("artillery.machinegunsound"))]
	sound.setAdditionalVolume(0.0)
	if Data.of("artillery.machinegunbarrels") >= 2:
		sound.setAdditionalVolume(-fastFireVolume)
	sound.play()
	
	recoil()

func getBarrelSet() -> Array:
	var barrelIndex : int = -1
	for i in barrels.size():
		if barrels[i].visible:
			barrelIndex = i
	var barrelRecoil = recoilAmount[barrelIndex]
	var barrelTop = barrelTops[barrelIndex]
	return [barrelTop, barrelRecoil]

func recoil():
	var barrelSet = getBarrelSet()
	var recoilY = barrelSet[1]
	var barrelTop = barrelSet[0]
	tween.remove_all()
	tween.interpolate_property(barrelTop, "position:y", recoilY, 0, 0.2, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()

func pauseChanged():
	if GameWorld.paused:
		tween.stop_all()
	else:
		tween.resume_all()

func ejectShell(isRight:=false):
	var emptyShell = EmptyShell.instantiate()
	for b in barrels:
		if b.visible:
			emptyShell.position = b.get_node("ShellEject").global_position
	var impulse = 120 if isRight else -120
	var initialImpulse : Vector2 = Vector2(impulse, -40.0).rotated(global_rotation+randf_range(-0.3, 0.3))*randf_range(0.7, 1.1)
	emptyShell.initialImpulse = initialImpulse
	$ShellEjectSound.play()
	Level.map.add_child(emptyShell)
