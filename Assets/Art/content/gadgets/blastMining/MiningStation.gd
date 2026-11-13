extends "res://content/gadgets/CellarGadget.gd"

var producing := false
var _hasMine := false
var growth := 0.0
var grownAfter := 0.0
var nextFlameAfter := 0.0

var flameCount:int

func _ready():
	flameCount = $Flames.get_child_count() + 1
	for c in $Flames.get_children():
		c.connect("animation_finished", Callable(self, "continueFlameAnimation").bind(c))
		c.visible = false
	addMine()
	
	Data.listen(self, "blastmining.bombsize")
	
	Style.init(self)
	
	Level.addTutorial(self, "blastmining")
	
	Achievements.addIfOpen(self, "BLASTMINING_USE")

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"blastmining.bombsize":
			updateBombSprite()

func serialize()->Dictionary:
	var data = super.serialize()
	data["producing"] = producing
	data["_hasMine"] = _hasMine
	data["growth"] = growth
	data["grownAfter"] = grownAfter
	data["flameCount"] = flameCount
	return data

func deserialize(data: Dictionary):
	super.deserialize(data)
	producing = data["producing"]
	_hasMine = data["_hasMine"]
	growth = data["growth"]
	grownAfter = data["grownAfter"]
	flameCount = data["flameCount"]
	
	if _hasMine:
		addMine()
	else:
		$Mine.visible = false
		
	if producing:
		$Flames.visible = true
		var flames_to_light = int(flameCount * pow(growth / grownAfter, 2))
		for c in $Flames.get_children():
			if flames_to_light > 0:
				c.visible = true
				c.play("start")
			else:
				c.visible = false
			flames_to_light -= 1
		updateNextFlameAfter()

func updateNextFlameAfter():
	var litFlames := 0
	for c in $Flames.get_children():
		if c.visible:
			litFlames += 1
		else:
			break
	
	var childCount = $Flames.get_children().size()
	var nextStep = sqrt((litFlames) / float(childCount))
	nextFlameAfter = nextStep * grownAfter

func continueFlameAnimation(f):
	f.play("run")

func _process(delta):
	if GameWorld.softPaused():
		return
	
	if growth < grownAfter:
		growth += delta 
		if nextFlameAfter <= growth:
			var pitch := 1.0
			for c in $Flames.get_children():
				if not c.visible:
					c.visible = true
					c.play("start")
					$FlameOn.pitch_scale = pitch
					$FlameOn.play()
					break
				pitch += 0.05
			updateNextFlameAfter()
		return
	
	if producing:
		addMine()
	elif not _hasMine:
		producing = true
		growth = 0.0
		grownAfter = GameWorld.getTimeBetweenWaves() * float(Data.of("blastMining.growthTime"))
		$Flames.visible = true
		for c in $Flames.get_children():
			c.visible = false
		updateNextFlameAfter()

func addMine():
	$MineReady.play()
	$Mine.visible = true
	$Mine.frame = 0
	$Mine.play()
	updateBombSprite()
	$Flames.visible = false
	producing = false
	_hasMine = true

func updateBombSprite():
	$Mine/Bomb.play("normal_" + str(min(100, Data.of("blastMining.bombsize"))))

func canFocusUse(keeper:Keeper) -> bool:
	return _hasMine

func useHold(keeper:Keeper) -> bool:
	return useHit(keeper)

func useHit(keeper:Keeper) -> bool:
	if _hasMine:
		for _i in Data.of("blastMining.bombs"):
			var mine = preload("res://content/gadgets/blastMining/Mine.tscn").instantiate()
			mine.position = $MinePosition.global_position
			Level.map.addDrop(mine)
			keeper.attachCarry(mine)
		_hasMine = false
		$Mine.visible = false
		$MinePickup.play()
		return true
	return false

func _on_mine_animation_looped() -> void:
	_MineAnimationFinishedCheck()

func _on_Mine_animation_finished() -> void:
	_MineAnimationFinishedCheck()

func _MineAnimationFinishedCheck() -> void:
	$Usable.updateFocus()

# for tutorial
func hasMine() -> bool:
	return _hasMine


