extends PanelContainer

signal leaderboard_not_found
signal leaderboard_found
signal leaderboard_score_upload_success
signal leaderboard_score_upload_failed
signal leaderboard_download_finished

const CHEATERBOARD = "domekeeper_prestige_cheats"

var leaderboardName = "domekeeper_prestige_weekly"

@onready var LeaderboardLoadingLabel = find_child("LeaderboardLoadingLabel")
@onready var FriendsLeaderboardContainerTemplate = find_child("FriendsLeaderboardContainer")
@onready var GlobalLeaderboardContainerTemplate = find_child("GlobalLeaderboardContainer")

var leaderboardGridContainers := {}

var leaderboardGlobalEntries:Array
var leaderboardRelativeEntries:Array
var leaderboardFriendEntries:Array

var ownRank:int = -1
var ownBestScore:int
var currentScore:int
var cheatHash:int
var rankCount:int #only for friends mode where we don't display the global rank

var lastDownload := 0
var nextDownload := 0

var season:int = 7
var uploadDone := false

var loadedBoards := []

var currentMode:String
var entryCount := 13

var mode_to_button_map := {}

func _ready():
	Platform.connectToLeaderboardCallbacks(leaderboard_Find_Result, leaderboard_Scores_Downloaded,leaderboard_Score_Uploaded)
	
	if isFriendsMode():
		find_child("FriendsOrGlobalButtons").visible = false
		find_child("ButtonShowFriends").button_pressed = true
	else:
		match GameWorld.lastLeaderboardSection:
			"global":
				find_child("ButtonShowLeaderboard").button_pressed = true
			_:
				find_child("ButtonShowFriends").button_pressed = true
	
	var seasonButtonsContainer = find_child("SeasonButtons")
	var label = seasonButtonsContainer.find_child("Label")
	label.text = tr("leaderboard.season").format({"season": ""}).strip_edges()
	var bg = ButtonGroup.new()
	for i in range(1, 1 + season):
		var button = Button.new()
		button.disabled = true
		button.toggle_mode = true
		button.text = str(i)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.connect("pressed", Callable(self, "setSeason").bind(i))
		button.button_pressed = i == season
		button.button_group = bg
		seasonButtonsContainer.add_child(button)
	
	for button in find_child("ModeButtons").get_children():
		var modeName = button.name.substr(10).to_lower() # cut off "ButtonMode"
		button.connect("pressed", Callable(self, "setMode").bind("prestige-" + modeName))
	
	Style.init(self)

func isFriendsMode() -> bool:
	return Level.stage is LevelStage and Level.loadout and Level.loadout.modeId == "prestige" and Level.loadout.difficulty < 0

func setButtonsDisabled(disabled:bool):
	find_child("ButtonShowFriends").disabled = disabled
	find_child("ButtonShowLeaderboard").disabled = disabled
	for button in find_child("SeasonButtons").get_children():
		if button is Button:
			button.disabled = disabled
	for button in find_child("ModeButtons").get_children():
		button.disabled = disabled
	
	LeaderboardLoadingLabel.visible = disabled
	
	if disabled:
		for global in find_child("LeaderboardContainer").get_children():
			global.visible = false
		for friend in find_child("FriendsContainer").get_children():
			friend.visible = false
	else:
		updateVisibleBoard()

func start(currentMode:String, showSeasonControls := true, showModeControls := false):
	self.currentMode = currentMode
	
	find_child("ButtonMode" + currentMode.substr(9).capitalize()).button_pressed = true # cut off "prestige-"
	find_child("SeasonButtons").visible = showSeasonControls
	find_child("ModeButtons").visible = showModeControls
	
	if CheatDetection.isRunning:
		cheatHash = CheatDetection.stop()
		Backend.event("cheat_stats", {"cheatHash": cheatHash})
	
	updateLeaderboardName()
	
#	if GameWorld.leaderboardHandles.has(leaderboardName):
#		Logger.info("Leaderboard already known, uploading score")
#		onLeaderboardFound()
#	else:
	Logger.info("Leaderboard " + str(leaderboardName) + " not cached, trying to find it")
	Platform.findOrCreateLeaderboard(leaderboardName, 2, 1)
	setButtonsDisabled(true)
	
	find_child("FriendsContainer").visible = find_child("ButtonShowFriends").button_pressed
	find_child("LeaderboardContainer").visible = find_child("ButtonShowLeaderboard").button_pressed

func updateLeaderboardName():
	if cheatHash > 0:
		leaderboardName = CHEATERBOARD
	else:
		match season:
			1: leaderboardName = "domekeeper_prestige_weekly"
			_: leaderboardName = "domekeeper_prestige_season" + str(season)
		
		match currentMode:
			CONST.MODE_PRESTIGE_COBALT:
				leaderboardName += "_cobalt"
			CONST.MODE_PRESTIGE_COUNTDOWN:
				leaderboardName += "_countdown"
			CONST.MODE_PRESTIGE_PROVOCATION:
				leaderboardName += "_provocation"
			CONST.MODE_PRESTIGE_MINER:
				leaderboardName += "_miner"
	
	if isFriendsMode():
		leaderboardName += "_friendly"
	
	prints("current leaderboard", leaderboardName)

func setOwnRank(ownRank):
	self.ownRank = ownRank

func leaderboard_Find_Result(handle: int, found: int) -> void:
	if found == 1:
		Logger.info("Leaderboard found")
		GameWorld.leaderboardHandles[leaderboardName] = handle
		onLeaderboardFound()
	else:
		Logger.error("Leaderboard not found")
		emit_signal("leaderboard_not_found")

func getOrCreateGridContainer(type:String):
	if not leaderboardGridContainers.has(season):
		leaderboardGridContainers[season] = {}
	var containersBySeason = leaderboardGridContainers.get(season)
	if not containersBySeason.has(currentMode):
		var friends = FriendsLeaderboardContainerTemplate.duplicate()
		find_child("FriendsContainer").add_child(friends)
		var global = GlobalLeaderboardContainerTemplate.duplicate()
		find_child("LeaderboardContainer").add_child(global)
		containersBySeason[currentMode] = {"friends": friends, "global": global}
	return containersBySeason[currentMode][type]

func fillLeaderboards():
	var isFriendsMode := isFriendsMode() 
	rankCount = 1
	var c = getOrCreateGridContainer("global")
	var isTop10 := false 
	for R in leaderboardGlobalEntries:
		var steamid = R.get("steam_id", 0)
		var isSelf:bool = str(steamid) == Platform.get_user_id()
		if isSelf:
			isTop10 = true
		
		var playerName = Platform.getFriendPersonaName(R.get("steam_id", 0))
		addRow(getRank(R, isFriendsMode), R.get("score", 0), R.get("details", []), playerName, c, isSelf)
	
	if not isTop10 and ownRank != -1:
		c.add_child(Control.new())
		var l = Label.new()
		l.text = "..."
		c.add_child(l)
		c.add_child(Control.new())
		c.add_child(Control.new())
		c.add_child(Control.new())
		c.add_child(Control.new())
		
		for R in leaderboardRelativeEntries:
			var steamid = R.get("steam_id", 0)
			var isSelf:bool = str(steamid) == Platform.get_user_id()
			var playerName = Platform.getFriendPersonaName(R.get("steam_id", 0))
			addRow(getRank(R, isFriendsMode), R.get("score", 0), R.get("details", []), playerName, c, isSelf)
	
	rankCount = 1
	c = getOrCreateGridContainer("friends")
	for R in leaderboardFriendEntries:
		var steamid = R.get("steam_id", 0)
		var isSelf:bool = str(steamid) == Platform.get_user_id()
		var playerName = Platform.getFriendPersonaName(R.get("steam_id", 0))
		addRow(getRank(R, isFriendsMode), R.get("score", 0), R.get("details", []), playerName, c, isSelf)

func getRank(R:Dictionary,isFriendsMode:bool) -> int:
	var rank:int
	if isFriendsMode:
		rank = rankCount
		rankCount += 1
	else:
		rank = R.get("global_rank", 0)
	return rank

func addRow(rank:int, score:int, details:Array, playerName:String, container, highlight := false):
	if playerName.length() > 24:
		playerName = playerName.substr(0, 24)
	var l = Label.new()
	l.text = "#" + str(rank)
	l.custom_minimum_size.x = 30
	if highlight:
		l.label_settings = preload("res://gui/fontsettings/NumbersFontSettingsHighlighted.tres")
	else:
		l.label_settings = preload("res://gui/fontsettings/NumbersFontSettings.tres")
	container.add_child(l)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l = Label.new()
	l.text = playerName
	l.size_flags_horizontal = Control.SIZE_EXPAND
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if highlight:
		l.label_settings = preload("res://gui/fontsettings/NormalFontSettingsHighlighted.tres")
	else:
		l.label_settings = preload("res://gui/fontsettings/NormalFontSettings.tres")
	container.add_child(l)
	
	if details.size() >= 3:
		container.add_child(getTextureRectFor(0, details[0]))
		container.add_child(getTextureRectFor(1, details[1]))
		container.add_child(getTextureRectFor(2, details[2]))
	
	l = Label.new()
	l.text = "%5.0f" % score
	l.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_RIGHT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if highlight:
		l.label_settings = preload("res://gui/fontsettings/NumbersFontSettingsHighlighted.tres")
	else:
		l.label_settings = preload("res://gui/fontsettings/NumbersFontSettings.tres")
	container.add_child(l)

func getTextureRectFor(col:int, value:int) -> TextureRect:
	var s = TextureRect.new()
	match col:
		0:
			match value:
				1: s.texture = preload("res://content/gamemode/prestige/leaderboard/dome1.png")
				2: s.texture = preload("res://content/gamemode/prestige/leaderboard/dome2.png")
				3: s.texture = preload("res://content/gamemode/prestige/leaderboard/dome3.png")
				4: s.texture = preload("res://content/gamemode/prestige/leaderboard/dome4.png")
		1:
			match value:
				1: s.texture = preload("res://content/gamemode/prestige/leaderboard/keeper1.png")
				2: s.texture = preload("res://content/gamemode/prestige/leaderboard/keeper2.png")
		2:
			match value:
				1: s.texture = preload("res://content/gamemode/prestige/leaderboard/gadget3.png")
				2: s.texture = preload("res://content/gamemode/prestige/leaderboard/gadget2.png")
				3: s.texture = preload("res://content/gamemode/prestige/leaderboard/gadget1.png")
				4: s.texture = preload("res://content/gamemode/prestige/leaderboard/gadget4.png")
	if s.texture:
		s.custom_minimum_size = s.texture.get_size() * 2
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return s

func onLeaderboardFound():
	if uploadDone:
		downloadLeaderboard()
	else:
		Platform.setLeaderboardDetailsMax(26)
		emit_signal("leaderboard_found")

func downloadLeaderboard():
	if loadedBoards.has(leaderboardName):
		setButtonsDisabled(false)
		return
	
	setButtonsDisabled(true)
	
	var h = GameWorld.leaderboardHandles[leaderboardName]
	lastDownload = nextDownload
	prints("loading", leaderboardName, nextDownload)
	match nextDownload:
		0:
			ownRank = -1
			Platform.downloadLeaderboardEntries(1, entryCount, 2, h)
			nextDownload += 1
		1:
			if ownRank <= entryCount:
				nextDownload += 2
				Platform.downloadLeaderboardEntries(1, entryCount, 0, h)
			else:
				nextDownload += 1
				Platform.downloadLeaderboardEntries(1, entryCount - 6, 0, h)
		2:
			nextDownload += 1
			Platform.downloadLeaderboardEntries(max(entryCount - ownRank, -3), 1, 1, h)
		3:
			fillLeaderboards()
			loadedBoards.append(leaderboardName)
			setButtonsDisabled(false)
			emit_signal("leaderboard_download_finished")
			prints("finished loading", leaderboardName)


func leaderboard_Scores_Downloaded(message: String, handle:int, result: Array):
	match lastDownload:
		0:
			leaderboardFriendEntries = result.duplicate()
			for entry in leaderboardFriendEntries:
				if str(entry.get("steam_id", "")) == Platform.get_user_id():
					ownRank = entry.get("global_rank", -1)
		1:
			leaderboardGlobalEntries = result.duplicate()
		2:
			leaderboardRelativeEntries = result.duplicate()
	downloadLeaderboard()

func uploadScore(score):
	self.currentScore = score
	if score > 0:
		var handle = GameWorld.leaderboardHandles.get(leaderboardName, 0)
		prints("uploading leaderboard score to handle", handle, "for board", leaderboardName)
		var keepBestScore = leaderboardName != CHEATERBOARD
		Platform.uploadLeaderboardScore(score, keepBestScore, generateHighscoreArray(), handle)
	else:
		downloadLeaderboard()
		emit_signal("leaderboard_score_upload_success", 0, 0, 0)
		ownRank = 0
		ownBestScore = 0

func leaderboard_Score_Uploaded(success: bool, this_handle: int, score: Dictionary) -> void:
	if success:
		# if the score didn't change, new rank and prev rank are 0 -> bug?
		Logger.info("new score uploaded", "PrestigeLeaderboard", score)
		uploadDone = true
		leaderboard_score_upload_success.emit(score["score_changed"], score["global_rank_new"], score["global_rank_prev"])
		ownRank = score["global_rank_new"]
		ownBestScore = score["score"]
		downloadLeaderboard()
	else:
		Logger.info("new score upload failed")
		emit_signal("leaderboard_score_upload_failed")
		$Tween.interpolate_callback(Platform, 10.0, "uploadLeaderboardScore", currentScore, true)
		$Tween.start()

func generateHighscoreArray() -> PackedInt32Array:
	# 0: dome id
	# 1: keeper id
	# 2: gadget id
	# 3: world id
	# 4: time
	# 5: baseperwave
	# 6: multiplier
	# 7: wave
	# 8: won
	# 9: cheat hash
	# 10: version hash
	# 11: mode variant
	# 12: blocks mined
	# 13: travelled distance
	# 14: monsters killed
	# 15: resources mined
	# 16: total time waves were present
	# 17: times saved
	# 18: total damage taken
	# 19: gadgets returned and gadgets shredded. Returned is value/100, shredded is value%100.
	# 20: total iron
	# 21: total water
	# 22: total cobalt
	# 23: times stalled
	# 24: total stall time
	# 25: spawnEscalation
	# 26: gameTimeWithoutDelay
	
	var d := []
	d.append(int(Level.loadout.domeId.substr(4)))
	var keeperId = Level.loadout.keepers.front().keeperId
	d.append(int(keeperId.substr(6)))
	match Level.loadout.primaryGadgetId:
		"orchard": d.append(1)
		"repellent": d.append(2)
		"shield": d.append(3)
		"droneyard": d.append(4)
		_: d.append(0)
	d.append(int(Level.loadout.worldId.substr(5)))
	d.append(int(GameWorld.runTime))
	d.append(int(Data.of("prestige.baseperwave")))
	d.append(int(Data.of("prestige.multiplier")))
	d.append(int(Data.of("monsters.cycle")))
	d.append(1 if GameWorld.won else 0)
	d.append(cheatHash)
	var versionParts = GameWorld.version.split(".")
	var versionHash = 1024 * int(versionParts[0].substr(1)) + int(versionParts[1])
	d.append(versionHash)
	var modeId:int
	match Level.loadout.modeConfig.get(CONST.MODE_CONFIG_PRESTIGE_VARIANT, ""):
		CONST.MODE_PRESTIGE_COUNTDOWN:
			modeId = 2
		CONST.MODE_PRESTIGE_MINER:
			modeId = 3
		_:
			modeId = 0
	d.append(modeId)
	d.append(int(GameWorld.runStats.get("tiles_destroyed", 0)))
	d.append(int(GameWorld.runStats.get("travelled_distance", 0)))
	d.append(int(GameWorld.runStats.get("monsters_killed", 0)))
	d.append(int(GameWorld.runStats.get("resources_mined", 0)))
	d.append(int(GameWorld.wavePresentTime))
	d.append(int(GameWorld.runStats.get("saves", 0)))
	d.append(int(GameWorld.runStats.get("damage_taken", 0)))
	d.append(int(GameWorld.runStats.get("gadgets_returned", 0) * 100 + GameWorld.runStats.get("gadgets_shredded", 0)))
	d.append(int(Data.of("inventory.totaliron")))
	d.append(int(Data.of("inventory.totalwater")))
	d.append(int(Data.of("inventory.totalsand")))
	d.append(int(GameWorld.runStats.get("waves_stalled", 0)))
	d.append(int(GameWorld.runStats.get("wave_stall_time", 0)))
	d.append(int(GameWorld.runStats.get("spawn_escalation", 0)))
	d.append(int(GameWorld.gameTimeWithoutDelay))
	
	return PackedInt32Array(d)

func _on_ButtonShowFriends_pressed():
	GameWorld.lastLeaderboardSection = "friends"
	updateVisibleBoard()

func _on_ButtonShowLeaderboard_pressed():
	GameWorld.lastLeaderboardSection = "global"
	updateVisibleBoard()

func updateVisibleBoard():
	if find_child("ButtonShowFriends").button_pressed:
		find_child("LeaderboardContainer").visible = false
		find_child("FriendsContainer").visible = true
		
		var containerToShow = getOrCreateGridContainer("friends")
		for container in find_child("FriendsContainer").get_children():
			container.visible = container == containerToShow
	else:
		find_child("LeaderboardContainer").visible = true
		find_child("FriendsContainer").visible = false
		
		var containerToShow = getOrCreateGridContainer("global")
		for container in find_child("LeaderboardContainer").get_children():
			container.visible = container == containerToShow

func setSeason(i:int):
	
	#adjust cobalt becoming provocation in season 6
	var modechange_boundary_passed = (season <6 and i >= 6) or (season >= 6 and i <6) 
	if modechange_boundary_passed:  
		%ButtonModeCobalt.visible = i < 6
		%ButtonModeProvocation.visible = i >= 6
		if i >= 6 and currentMode == CONST.MODE_PRESTIGE_COBALT:
			currentMode = CONST.MODE_PRESTIGE_PROVOCATION
			%ButtonModeProvocation.set_pressed_no_signal(true)
		elif i <6 and currentMode == CONST.MODE_PRESTIGE_PROVOCATION:
			currentMode = CONST.MODE_PRESTIGE_COBALT
			%ButtonModeCobalt.set_pressed_no_signal(true)
	
	season = i
	updateLeaderboardName()
	lastDownload = 0
	nextDownload = 0
#	if GameWorld.leaderboardHandles.has(leaderboardName):
#		downloadLeaderboard()
#	else:
	Platform.findOrCreateLeaderboard(leaderboardName, 2, 1)
	setButtonsDisabled(true)

func setMode(mode:String):
	currentMode = mode
	updateLeaderboardName()
	lastDownload = 0
	nextDownload = 0
	Platform.findOrCreateLeaderboard(leaderboardName, 2, 1)
	setButtonsDisabled(true)
