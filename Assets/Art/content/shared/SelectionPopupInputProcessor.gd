extends "res://gui/PopupInput.gd"

signal option_selected

var lastOptionFocussed
var endAfterSelection := true

func handleStart():
	super.handleStart()
	Level.stage.inputDeviceLimit = deviceId

func handleStop():
	super.handleStop()
	Level.stage.inputDeviceLimit = -1

func becameLeaf():
	if lastOptionFocussed:
		lastOptionFocussed.grab_focus()
		lastOptionFocussed = null
	InputSystem.changeCursor("default")
	GameWorld.setShowMouse(Options.useMouseMenus)

func notLeaf():
	lastOptionFocussed = popup.get_viewport().gui_get_focus_owner()

func buttonEvent(event) -> bool:
	if justPressed(event, "ui_select"):
		var focus = popup.getFocussedOption()
		if not focus:
			return true
			
		
		trySelectOption(focus)
		return true
	return super.buttonEvent(event)

func trySelectOption(option):
	if option.canBeSelected():
		Audio.sound("gui_select")
		emit_signal("option_selected", option)
		if endAfterSelection:
			desintegrate()
	else:
		Audio.sound("gui_err")
