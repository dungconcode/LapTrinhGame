extends Node2D

class_name SecondaryWeapon

var playerControlled := false
var move:Vector2
var currentSpeed := 0.0
var acceleration := 0.0
var firing := false

func start():
	pass

func stop():
	pass

func inputs(moveValue:Vector2, fireValue:float, specialValue:float):
	firing = fireValue > 0.0
	move = moveValue

func setPlayerControlled():
	playerControlled = true
