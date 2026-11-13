extends CenterContainer

signal quit

func init():
	find_child("SuccessPopup").visible = false
	find_child("LoadingSpinner").visible = false
	find_child("ErrorLabel").visible = false
	find_child("PanelContainer").visible = true

func _on_SubmitButton_pressed():
	Backend.trackRequest("SubmitBugReport")
	
	find_child("SubmitButton").visible = false
	find_child("LoadingSpinner").visible = true
	find_child("ErrorLabel").visible = false
	var data = {}
	data["description"] = find_child("Content1").text
	data["context"] = find_child("Content2").text
	data["playerId"] = GameWorld.playerId
	data["sceneContext"] = StageManager.getContext()
	
	var headers = ["Content-Type: text/plain"]
	var body = Marshalls.utf8_to_base64(JSON.stringify(data))
#	$SubmitBugReport.request(
#		Backendless.BASEURL
#			+"/"+Backendless.APP_ID
#			+"/"+Backendless.apiKey
#			+"/files/binary/bugs/"+GameWorld.generateUid()+".txt" + "?overwrite=true",
#		headers,
#		true,
#		HTTPClient.METHOD_PUT,
#		body
#	)

func _on_ButtonQuit_pressed():
	emit_signal("quit")

func _on_SubmitBugReport_request_completed(result, response_code, headers, body):
	Backend.trackResponse("SubmitBugReport", result, response_code)
	find_child("SubmitButton").visible = true
	find_child("LoadingSpinner").visible = false
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
#		Tracking.errorHttp("_on_SubmitBugReport_request_completed", result, response_code, body.get_string_from_utf8())
		find_child("ErrorLabel").text = "An error occurred ("+str(response_code)+"), the bug report could not be sent."
		find_child("ErrorLabel").visible = true
		return

	find_child("PanelContainer").visible = false
	find_child("SuccessPopup").visible = true
	find_child("Content1").text = ""
	find_child("Content2").text = ""
