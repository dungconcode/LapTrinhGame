extends HudElement

var secondsPerPixel := 4.0

var goalRectSize := 0.0
var maxSpawnRectSize := 25.0
var maxDelayRectSize := 25.0
var maxDelay := 0.0
var lastTimeBetweenWaves := 0.0

@onready var MonsterSpawnRect = $Box/TimeBar/FillingBar
@onready var WaveDelayRect = $Box/TimeBar/DelayBar/FillingBar

const colorKeyInactive := Color(32.0/255.0, 0, 220.0/256.0)
const colorKeyActive := Color(96.0/255.0, 0, 220.0/256.0)

var listenToWarner:bool
var warningPlayed:bool
var keeperInDomeAfterWarning:bool
var waveStarted:bool
var timeSinceHome := 0.0
var timeSinceWaveStarted := 0.0

var pathToDomeLine

func _ready():
	super._ready()
	$Box/TimeBar.visible = false
	$Box/TimeBar/DelayBar.visible = false
	MonsterSpawnRect.visible = false
	$Box/Normal/Flare.visible = false
	$Box/WaveLabelContainer.visible = false
	warningPlayed = false
	
	if not GameWorld.isUpgradeLimitAvailable("hostile"):
		$Box/Normal.visible = false
	
	if GameWorld.boughtUpgrades.has("repellent"):
		$Box/TimeBar/DelayBar.visible = true
		updateDelayBarLayout()
	
	updateSizeAndRebuild()

func init():
	super.init()
	WaveDelayRect.size.x = 0
	Data.listen(self, "event.keepers.insidestation")
	Data.listen(self, "monsters.wavepresent")
	Data.listen(self, "monsters.cycle", true)
	Data.listen(self, "game.over")
	Data.listen(self, "wavemeter.showbar", true)
	Data.listen(self, "wavemeter.showcounter", true)
	Data.listen(self, "wavemeter.warner", true)
	Data.listen(self, "monsters.wavecooldown", true)
	
func _process(delta):
	var sizeD = goalRectSize - MonsterSpawnRect.size.x
	sizeD += sign(sizeD)
	MonsterSpawnRect.size.x = min(maxSpawnRectSize - 1, MonsterSpawnRect.size.x + delta * GameWorld.cycleSpeed * sizeD)
	
	var delay = Data.of("monsters.wavedelay")
	if delay > 0:
		$Box/TimeBar/DelayBar.visible = true
		if delay > maxDelay:
			maxDelay = delay
			updateDelayBarLayout()
		var delayRectSize = (delay / maxDelay) * maxDelayRectSize
		WaveDelayRect.size.x = delayRectSize
		MonsterSpawnRect.color = Style.mapColor(colorKeyInactive)
		WaveDelayRect.color = Style.mapColor(colorKeyActive)
	elif $Box/TimeBar/DelayBar.visible:
		maxDelay = 0
		MonsterSpawnRect.color = Style.mapColor(colorKeyActive)
		WaveDelayRect.color = Style.mapColor(colorKeyInactive)
	
	if not GameWorld.paused and warningPlayed:
		if keeperInDomeAfterWarning:
			timeSinceHome += delta
		if waveStarted:
			timeSinceWaveStarted += delta

func propertyChanged(property:String, oldValue, newValue):
	match property:
		"monsters.cycle":
			updateTimeBarLayout()
			updateSizeAndRebuild()
			var fixedCycles = Data.ofOr("run.durationcycles", -1)
			if fixedCycles > 0:
				%WaveLabel.text = str(min(99, fixedCycles - newValue))
			else:
				%WaveLabel.text = str(min(99, newValue + 1))
		"wavemeter.warner": 
			listenToWarner = newValue
			if newValue and newValue != oldValue:
				Data.listen(self, "event.keepers.insidedome")
		"monsters.wavecooldown": 
			goalRectSize = (maxSpawnRectSize - 1) * newValue / lastTimeBetweenWaves
			if not Data.ofOr("wavemeter.warnermuted",false) and listenToWarner and not warningPlayed:
				for keeper in Keepers.getAll():
					var keeperDist = keeper.global_position.length()
					if keeperDist > 150:
						var threshold = 1.5 + (6.0 + keeperDist * 0.01) * GameWorld.waveMeterWarningModifier
						if newValue <= threshold:
							warningPlayed = true
							if playerId == "player1":
								$WarnSound.play()
							$Box/Normal/Flare.visible = true
							var frequency := 0.4
							$MonsterSpawnTween.interpolate_callback($Box/Normal/Flare, frequency, "set", "visible", false)
							$MonsterSpawnTween.interpolate_callback($Box/Normal/Flare, frequency * 1.5, "set", "visible", true)
							$MonsterSpawnTween.interpolate_callback($WarnSound, frequency * 1.5, "play")
							$MonsterSpawnTween.interpolate_callback($Box/Normal/Flare, frequency * 2.5, "set", "visible", false)
							$MonsterSpawnTween.interpolate_callback($Box/Normal/Flare, frequency * 3.0, "set", "visible", true)
							$MonsterSpawnTween.interpolate_callback($WarnSound, frequency * 3.0, "play")
							$MonsterSpawnTween.interpolate_callback($Box/Normal/Flare, frequency * 4.0, "set", "visible", false)
							$MonsterSpawnTween.start()
							
							if Data.of("wavemeter.pathtodome"):
								showPathToDome(keeper)
							return
		"event.keepers.insidedome":
			if Keepers.allInsideDome():
				if pathToDomeLine:
					removePathToDome()

				if warningPlayed:
					keeperInDomeAfterWarning = true
					if waveStarted:
						updateWaveWarningModifier()
		"event.keepers.insidestation":
			if Keepers.oneInsideStation():
				$Box/Normal/Flare.visible = Data.of("monsters.wavepresent")
		"monsters.wavepresent": 
			if visible:
				if newValue:
					switchFlare()
					waveStarted = true
					if keeperInDomeAfterWarning:
						updateWaveWarningModifier()
				else:
					if playerId == "player1" and GameWorld.isUpgradeLimitAvailable("hostile") and oldValue != newValue:
						$WaveEndSound.playDelayed(1.0)
					stopFlare()
					warningPlayed = false
					keeperInDomeAfterWarning = false
					waveStarted = false
					timeSinceHome = 0.0
					timeSinceWaveStarted = 0.0
					if pathToDomeLine:
						removePathToDome()
		"wavemeter.showbar":
			if newValue and not $Box/TimeBar.visible:
				$Box/TimeBar.visible = true
				MonsterSpawnRect.visible = true
				updateTimeBarLayout()
				updateSizeAndRebuild()
		"wavemeter.showcounter":
			if newValue and not $Box/WaveLabelContainer.visible:
				$Box/WaveLabelContainer.visible = true
				$Box/TimeBar.position.x += 12
				$Box/Normal.position.x += 12
				updateSizeAndRebuild()
		"game.over":
			if newValue == "won" or newValue == "lost":
				stopFlare()

func updateSizeAndRebuild():
	await get_tree().process_frame # ui often needs a frame to update properly
	await get_tree().process_frame
	
	element_size.x = ceil(size.x / 6.0)
	emit_signal("request_rebuild")

func updateTimeBarLayout():
	lastTimeBetweenWaves = GameWorld.getTimeBetweenWaves()
	maxSpawnRectSize = floor(lastTimeBetweenWaves / secondsPerPixel)
	$Box/TimeBar.custom_minimum_size.x = maxSpawnRectSize
	$Box/TimeBar/Terminus.position.x = maxSpawnRectSize

func updateDelayBarLayout():
	maxDelayRectSize = floor(maxDelay / secondsPerPixel)
	$Box/TimeBar/DelayBar.custom_minimum_size.x = maxDelayRectSize
	$Box/TimeBar/DelayBar/Terminus.position.x = maxDelayRectSize

func updateWaveWarningModifier():
	assert(keeperInDomeAfterWarning)
	assert(waveStarted)
	
	if timeSinceWaveStarted > 0.3:
		#too late
		GameWorld.waveMeterWarningModifier = clamp(GameWorld.waveMeterWarningModifier * min(1.3, 1.0 + timeSinceWaveStarted * 0.075), 0.5, 2.0)
	if timeSinceHome > 1.5:
		# too early
		GameWorld.waveMeterWarningModifier = clamp(GameWorld.waveMeterWarningModifier * max(0.7, 1.0 - timeSinceHome * 0.05), 0.5, 2.0)

func stopFlare():
	$MonsterSpawnTween.stop_all()
	$MonsterSpawnTween.remove_all()
	$Box/Normal/Flare.visible = false

func switchFlare():
	if Data.of("monsters.wavepresent"):
		var delay:float
		if Keepers.oneInsideStation():
			$Box/Normal/Flare.visible = true
			delay = 0.3
		else:
			$Box/Normal/Flare.visible = not $Box/Normal/Flare.visible
			if $Box/Normal/Flare.visible:
				Audio.sound("alarm") 
				delay = 0.1
			else:
				delay = 0.9
				
			
		$MonsterSpawnTween.interpolate_callback(self, delay, "switchFlare")
		$MonsterSpawnTween.start()
	else:
		$Box/Normal/Flare.visible = false

func pauseChanged():
	if GameWorld.paused:
		$MonsterSpawnTween.stop_all()
	else:
		$MonsterSpawnTween.resume_all()

func showPathToDome(keeper:Keeper):
	pathToDomeLine = preload("res://content/hud/wavemeter/PathHome.tscn").instantiate()
	for offset in CONST.PATHFINDING_OFFSETS:
		var path = Level.map.findPath(keeper.global_position + offset, Vector2(0, -1) * GameWorld.TILE_SIZE + CONST.TILE_OFFSET)# * GameWorld.TILE_SIZE + CONST.TILE_OFFSET)
		if path:
			for p in path:
				pathToDomeLine.add_point(p)
				pathToDomeLine.add_point(p)
			pathToDomeLine.add_point(Vector2(0, -3) * GameWorld.TILE_SIZE + CONST.TILE_OFFSET)
			pathToDomeLine.modulate.a = 0.0
			Level.map.add_child(pathToDomeLine)
			Style.init(pathToDomeLine)
			$PathToDomeTween.interpolate_property(pathToDomeLine, "modulate:a", 0.0, 0.6, 0.4)
			$PathToDomeTween.start()
			return

func removePathToDome():
	if pathToDomeLine:
		$PathToDomeTween.stop_all()
		$PathToDomeTween.remove_all()
		$PathToDomeTween.interpolate_property(pathToDomeLine, "modulate:a", pathToDomeLine.modulate.a, 0.0, 0.4)
		$PathToDomeTween.interpolate_callback(pathToDomeLine, 0.5, "queue_free")
		pathToDomeLine = null
		$PathToDomeTween.start()
