extends Node2D

func play(powervfx, shotPosition, quickshot:=false):
	position = shotPosition
	match int(powervfx):
		
		0:
			if quickshot:
				$Quickshotsound.play()
				$Shot0.setAdditionalVolume(-5)
			$Shot0.play()
			$Shot0.connect("finished", Callable(self, "queue_free"))
		1:
			if quickshot:
				$Quickshotsound.play()
				$Shot1.setAdditionalVolume(-5)
			$Shot1.play()
			$Shot1.connect("finished", Callable(self, "queue_free"))
		2:
			if quickshot:
				$Quickshotsound.play()
				$Shot2.setAdditionalVolume(-5)
			$Shot2.play()
			$Shot2.connect("finished", Callable(self, "queue_free"))
		3:
			if quickshot:
				$Quickshotsound.play()
				$Shot0.setAdditionalVolume(-5)
			$Shot3.play()
			$Shot3.connect("finished", Callable(self, "queue_free"))
		4:
			if quickshot:
				$Quickshotsound.play()
				$Shot4.setAdditionalVolume(-3)
			$Shot4.play()
			$Shot4.connect("finished", Callable(self, "queue_free"))

