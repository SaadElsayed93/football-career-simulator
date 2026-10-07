extends Control

func _ready() -> void:
	print("Football Career Simulator started!")

	var test_player := PlayerData.new()
	test_player.player_name = "Test Player"
	test_player.age = 14
	test_player.nationality = "Egypt"
	test_player.height_cm = 175
	test_player.weight_kg = 68

	SaveManager.current_player = test_player


func _on_button_pressed() -> void:
	print("Continue Career pressed!")
	SaveManager.load_game()

func _on_start_new_career_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CreateCareer.tscn")
func _on_import_career_pressed() -> void:
	print("Import Career pressed!")


func _on_settings_pressed() -> void:
	print("Settings pressed!")


func _on_exit_pressed() -> void:
	print("Exit pressed!")
