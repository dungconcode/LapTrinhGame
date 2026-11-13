extends PanelContainer

signal proceed
signal back

@export var showButtons := false

var isIn := false
var animationDone := false
var selectedUnlockable := ""
var firstPanel

func init():
	if GameWorld.unlockableElements.size() == 0:
		visible = false
		return
	
	while GameWorld.unlockableElements.size() > 3:
		# you might think this will result in a different choice each time it is opened after going back to the run stats, but it's not. Just saying, in case you are wondering.
		GameWorld.unlockableElements.remove_at(randi() % GameWorld.unlockableElements.size())
	
	for u in GameWorld.unlockableElements:
		var panel = preload("res://content/gamemode/unlockables/UnlockOption.tscn").instantiate()
		panel.init(u)
		find_child("Options").add_child(panel)
		if selectedUnlockable == "":
			selectedUnlockable = u
			panel.grab_focus()
			panel.pressed()
			firstPanel = panel
		panel.connect("selected", Callable(self, "unlockableSelected").bind(u))
	
	find_child("Buttons").visible = showButtons
	
	Style.init(self)

func unlockableSelected(u):
	selectedUnlockable = u
	for c in find_child("Options").get_children():
		if u != c.id:
			c.releasePressed()

func applyUnlockable():
	if selectedUnlockable == "---":
		# just to block accidental multi unlocks
		return
	
	if selectedUnlockable != "":
		GameWorld.unlockElement(selectedUnlockable)
		Achievements.reactOnUnlock(selectedUnlockable)
		selectedUnlockable = "---"
		SaveGame.persistMetaState()

func _on_ProceedButton_pressed():
	find_child("ProceedButton").release_focus()
	find_child("ProceedButton").disabled = true
	find_child("CancelButton").disabled = true
	for c in find_child("Options").get_children():
		c.disabled = true
		if selectedUnlockable != c.id:
			c.reject()
		else:
			c.highlight()
	Audio.sound("gui_unlock_upgrade")
	$Tween.interpolate_property(self, "position", position, position + Vector2(0, -25), 1.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "position", position + Vector2(0, -25), position + Vector2(0, 1000), 0.5, Tween.TRANS_BACK, Tween.EASE_IN, 1.0)
	$Tween.interpolate_callback(self, 1.5, "emit_signal", "proceed")
	$Tween.start()

func _on_CancelButton_pressed():
	emit_signal("back")
	find_child("CancelButton").disabled = true
	find_child("ProceedButton").disabled = true

func getFirstPanel():
	return firstPanel
