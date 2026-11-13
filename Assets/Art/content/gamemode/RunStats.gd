extends Container

var titles := {
	"waves_survived": "level.gameover.stats.wavessurvived",
	"monsters_killed": "level.gameover.stats.monsterskilled",
	"time": "level.gameover.stats.timeplayed",
	"tiles_destroyed": "level.gameover.stats.destroyedblocks",
	"travelled_distance": "level.gameover.stats.distancetravelled",
	"resources_mined": "level.gameover.stats.resourcesmined",
	"difficulty": "level.gameover.stats.difficulty",
	"mapsize": "level.gameover.stats.mapsize",
	"additionalgadget": "level.gameover.stats.additionalgadget",
#	"lowest_hp": "Monsters Killed",
#	"damage_taken": "Monsters Killed",
}

var runFinishedPopup

func init(runFinishedPopup):
	self.runFinishedPopup = runFinishedPopup
	
	GameWorld.runStats["time"] = ("%.0f" % (GameWorld.runTime/60)) + tr("level.gameover.stats.timeplayed.unit")
	GameWorld.runStats["travelled_distance"] = ("%.1f" % (GameWorld.travelledDistance * CONST.PixelPerKilometer)) + "km"
	
	if Level.loadout.modeId == CONST.MODE_RELICHUNT:
		GameWorld.runStats["mapsize"] = CONST.mapSizesStringsById.get(Level.loadout.modeConfig.get(CONST.MODE_CONFIG_MAP_ARCHETYPE, ""), "missing")
		GameWorld.runStats["difficulty"] = CONST.difficultyStringByInt.get(int(Level.loadout.difficulty))
	else:
		titles.erase("mapsize")
		titles.erase("difficulty")
	
	if GameWorld.gadgetToKeep == "" or Level.loadout.modeId != CONST.MODE_RELICHUNT:
		titles.erase("additionalgadget")
	else:
		GameWorld.runStats["additionalgadget"] = "upgrades." + GameWorld.gadgetToKeep + ".title" 
	
	if GameWorld.runStats.has("monsters_killed"):
		GameWorld.runStats["monsters_killed"] = round(GameWorld.runStats["monsters_killed"])
	
	var i := 0
	for key in titles:
		var container = $GridContainerLeft if i < titles.size() * 0.5 else $GridContainerRight
		var value = GameWorld.runStats.get(key, 0)
		var l = Label.new()
		l.text = tr(titles[key])+": "
		container.add_child(l)
		l = Label.new()
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.text = str(value)
		container.add_child(l)
		i += 1
	
	%ButtonStats.visible = Data.ofOr("postrun.additionalstats", false)
	%ButtonMap.visible = Data.ofOr("postrun.miningtimelapse", false)
	$VBoxContainer.visible = %ButtonStats.visible or %ButtonMap.visible

func _on_button_monster_count_pressed() -> void:
	Audio.sound("gui_select")
	var i = preload("res://content/shared/ControllerScrollInputProcessor.gd").new()
	i.popup = preload("res://content/gamemode/DetailedStats.tscn").instantiate()
	i.scrollTarget = i.popup.find_child("ScrollContainer").get_v_scroll_bar()
	i.stopping.connect(i.popup.queue_free)
	i.stopping.connect(runFinishedPopup.updateFocus)
	Level.stage.showPopup(i.popup)
	i.integrate(Level.stage)

func _on_button_map_pressed() -> void:
	Audio.sound("gui_select")
	var i = preload("res://gui/PopupInput.gd").new()
	i.popup = preload("res://content/gamemode/summary/MiningSummary.tscn").instantiate()
	i.stopping.connect(i.popup.queue_free)
	i.stopping.connect(runFinishedPopup.updateFocus)
	Level.stage.showPopup(i.popup)
	i.integrate(Level.stage)
