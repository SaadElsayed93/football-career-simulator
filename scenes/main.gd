extends Control

func _on_button_pressed() -> void:
	if SaveManager.load_game():
		get_tree().change_scene_to_file("res://scenes/CareerDashboard.tscn")

func _on_start_new_career_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CreateCareer.tscn")
func _on_import_career_pressed() -> void:
	print("Import Career pressed!")


func _on_settings_pressed() -> void:
	print("Settings pressed!")


func _on_exit_pressed() -> void:
	print("Exit pressed!")
