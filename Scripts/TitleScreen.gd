extends Control


func _on_SoloButton_button_up():
	get_tree().change_scene("res://Scenes/Game.tscn")


func _on_ExitButton_button_down():
	get_tree().quit()
