extends PanelContainer

var currentlySelected = null

var firstOption = null

func init():
	var gadgets := []
	for g in Data.gadgets:
		if GameWorld.boughtUpgrades.has(g) and Data.gadgets[g].get("type", "nope") == "gadget":
			gadgets.append(g)
	
	for g in Level.loadout.additionalGadgets:
		gadgets.erase(g)

	if gadgets.size() == 0:
		visible = false
		return
	
	for id in gadgets:
		var choice = preload("res://content/gamemode/gadgetchoice/GadgetOption.tscn").instantiate()
		choice.init(id)
		choice.connect("selected", Callable(self, "gadgetSelected").bind(choice))
		find_child("GadgetContainer").add_child(choice)
		if GameWorld.gadgetToKeep == id:
			choice.select()
			firstOption = choice
			currentlySelected = choice
		if not firstOption:
			firstOption = choice
	
	if not currentlySelected:
		GameWorld.gadgetToKeep = ""
	
	updateKeepingLabel()
	GameWorld.keptGadgetUsed = false
	
	Style.init(self)

func updateKeepingLabel():
	var gadgetName:String
	if currentlySelected:
		gadgetName = tr("upgrades." + GameWorld.gadgetToKeep + ".title" )
		find_child("SelectedGadgetLabel").text = tr("level.gameover.keepgadget.keeping").format({"gadget": gadgetName})
	else:
		gadgetName = tr("level.gameover.keepgadget.none")
		find_child("SelectedGadgetLabel").text = "[wave amp=20 freq=6]" + tr("level.gameover.keepgadget.keeping").format({"gadget": gadgetName}) + "[/wave]"

func gadgetSelected(gadgetPanel):
	Audio.sound("gui_select")
	
	if currentlySelected:
		currentlySelected.deselect()
		if currentlySelected == gadgetPanel:
			GameWorld.gadgetToKeep = ""
			currentlySelected = null
			updateKeepingLabel()
			return
	
	currentlySelected = gadgetPanel
	currentlySelected.select()
	GameWorld.gadgetToKeep = gadgetPanel.id
	GameWorld.keptGadgetUsed = false
	SaveGame.persistMetaState()
	updateKeepingLabel()

func getFirstOption():
	return firstOption
