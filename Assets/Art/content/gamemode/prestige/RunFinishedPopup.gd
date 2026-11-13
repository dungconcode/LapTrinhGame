extends CenterContainer

var isIn := false
var inScoreCount := false

@onready var ScoreLabel = find_child("ScoreLabel")
@onready var ScoreUploadResult = find_child("ScoreUploadResult")
@onready var Leaderboard = find_child("PrestigeLeaderboard")

var currentScore:int
var totalScore:int
var currentTime:float
var totalTime:float

var scoreUploadMessage:String
var shoulShowUploadMessage := false

func _ready():
	if get_parent() == get_tree().root:
		Platform.init(false)
		Data.apply("prestige.baseperwave", 10)
		Data.apply("prestige.multiplier",1)
		Data.apply("monsters.cycle",1)
		Data.apply("prestige.score",10010)
		Data.apply("prestige.sentcobalt",1)
		Data.apply("inventory.totalsand",1)
		GameWorld.version = "v1.1"
		$Tween.interpolate_callback(self, 0.3, "startScoreCount")
		$Tween.start()
	
	find_child("RunStats").init(self)
	ScoreLabel.text = "0"
	
	find_child("AnotherRunButton").visible = true
	find_child("VariationLabel").visible = true
	find_child("TitleLabel").text = "level.gameover.prestige.title"
	match Level.loadout.modeConfig.get(CONST.MODE_CONFIG_PRESTIGE_VARIANT):
		CONST.MODE_PRESTIGE_COUNTDOWN:
			find_child("VariationLabel").text = tr("loadout.prestige.countdown")
		CONST.MODE_PRESTIGE_PROVOCATION:
			find_child("VariationLabel").text = tr("loadout.prestige.provocation")
		CONST.MODE_PRESTIGE_MINER:
			find_child("VariationLabel").text = tr("loadout.prestige.miner")
		CONST.MODE_PRESTIGE_ENDLESS:
			find_child("VariationLabel").text = tr("loadout.prestige.endless")
	
	if Level.difficulty() < 0:
		find_child("VariationLabel").text += " (" + tr("loadout.prestige.friend.mode") + ")"
	
	Style.init(self)
	
	ScoreUploadResult.text = ""
	scoreUploadMessage = tr("level.gameover.prestige.uploading.inprocess")
	totalScore = Data.of("prestige.score")
	
	Leaderboard.connect("leaderboard_not_found", onLeaderboardNotFound)
	Leaderboard.connect("leaderboard_found", onLeaderboardFound)
	Leaderboard.connect("leaderboard_score_upload_success", leaderboard_Score_Upload_Success)
	Leaderboard.connect("leaderboard_score_upload_failed", leaderboard_Score_Upload_Failed)
	
	Leaderboard.start(Level.loadout.modeConfig.get(CONST.MODE_CONFIG_PRESTIGE_VARIANT, ""))
	
	if GameWorld.won and GameWorld.unlockableElements.size() > 0:
		find_child("MainMenuButton").visible = false
		find_child("AnotherRunButton").visible = false
		find_child("UnlockElementButton").visible = true
	else:
		find_child("MainMenuButton").visible = true
		find_child("AnotherRunButton").visible = true
		find_child("UnlockElementButton").visible = false
	
	if not Data.ofOr("postrun.showmine", false):
		find_child("MineViewButton").visible = false

func onLeaderboardNotFound():
	scoreUploadMessage = tr("level.gameover.prestige.uploading.finalfailed")
	updateScoreUploadLabel()

func onLeaderboardFound():
	ScoreUploadResult.text = tr("level.gameover.prestige.uploading.inprocess")
	Leaderboard.uploadScore(totalScore)

func _process(delta):
	if not inScoreCount:
		return
	
	if currentTime > totalTime or ScoreLabel.text == str(totalScore):
		currentTime = totalTime
		inScoreCount = false
		$FinalRaised.play()
		ScoreLabel.pivot_offset = ScoreLabel.size * 0.5
		$Tween.interpolate_property(ScoreLabel, "scale", Vector2.ONE * 3, Vector2.ONE, 0.5, Tween.TRANS_EXPO, 0, 0.1)
		$Tween.interpolate_callback($FinalDropped, 0.5, "play")
		$Tween.interpolate_callback(self, 1.0, "set", "shoulShowUploadMessage", true)
		$Tween.interpolate_callback(self, 1.1, "updateScoreUploadLabel")
		$Tween.start()
		
	var fraction = currentTime / totalTime
	var newText = str("%.0f" % (fraction * totalScore))
	
	if newText != ScoreLabel.text:
		ScoreLabel.text = newText
		$Ping.play()
	
	var deltaMod = 1.0 - 1.99 * abs(0.5 - fraction)
	currentTime += delta * 10000 * pow(min(deltaMod, 0.05), 3)

func updateScoreUploadLabel():
	# needs this, as the text could change after the tween for setting it is started
	if shoulShowUploadMessage:
		ScoreUploadResult.text = scoreUploadMessage
	else:
		ScoreUploadResult.text = ""

func startScoreCount():
	totalTime = 1.0 + pow(abs(totalScore), 0.4) * 0.02
	inScoreCount = true

func leaderboard_Score_Upload_Failed() -> void:
	shoulShowUploadMessage = true
	scoreUploadMessage = tr("level.gameover.prestige.uploading.failed")
	updateScoreUploadLabel()
	shoulShowUploadMessage = false

func leaderboard_Score_Upload_Success(score_changed: int, new_rank: int, prev_rank:int) -> void:
	scoreUploadMessage = ""
	if score_changed == 1:
		scoreUploadMessage = tr("level.gameover.prestige.score.personalbest") + " "
	if new_rank == prev_rank:
		scoreUploadMessage += tr("level.gameover.prestige.score.rankunchanged")
	else:
		scoreUploadMessage += tr("level.gameover.prestige.score.rankimproved").format({"rank": new_rank})
	updateScoreUploadLabel()

func moveIn():
	if isIn:
		return
	
	GameWorld.setShowMouse(Options.useMouseMenus)
	isIn = true
	$Tween.stop_all()
	$Tween.remove_all()
	$Tween.interpolate_property(self, "position:y", position.y, (get_viewport_rect().size.y-size.y)*0.5, 1.2, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, 1.3, "startScoreCount")
	$Tween.interpolate_callback(self, 3.0, "updateFocus")
	$Tween.start()

func moveOut():
	if not isIn:
		return
	
	isIn = false
	$Tween.interpolate_property(self, "position:y", position.y, get_viewport_rect().size.y, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	$Tween.interpolate_callback(self, 0.5, "queue_free")
	$Tween.start()

func _on_MainMenuButton_pressed():
	if isIn:
		continuePressed()
		StageManager.startStage("stages/title/title")

func _on_AnotherRunButton_pressed():
	if isIn:
		continuePressed()
		StageManager.startStage("stages/loadout/multiplayerloadout")

func continuePressed():
	Audio.stopMusic()
	Audio.sound("gui_select")
	find_child("MainMenuButton").disabled = true
	find_child("AnotherRunButton").disabled = true
	find_child("MineViewButton").disabled = true

func _on_UnlockElementButton_pressed():
	Audio.sound("gui_select")
	var i = preload("res://gui/PopupInput.gd").new()
	var unlockablesPopup = preload("res://content/gamemode/unlockables/UnlockablesPopup.tscn").instantiate()
	unlockablesPopup.connect("proceed", i.desintegrate)
	unlockablesPopup.connect("back", i.desintegrate)
	unlockablesPopup.connect("back", updateFocus)
	unlockablesPopup.connect("back", unlockablesPopup.queue_free)
	get_parent().add_child(unlockablesPopup)
	i.popup = unlockablesPopup
	i.integrate(Level.stage)

func updateFocus():
	if find_child("AnotherRunButton").visible:
		InputSystem.grabFocus(find_child("AnotherRunButton"))
	else:
		InputSystem.grabFocus(find_child("UnlockElementButton"))

func _on_MineViewButton_pressed():
	if isIn:
		Level.stage.startMineView()

func focusMineViewButton():
	InputSystem.grabFocus(find_child("MineViewButton"))
