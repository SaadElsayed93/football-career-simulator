extends Node

const SAVE_PATH := "user://career_save.json"

var current_player: PlayerData


func save_game() -> void:
	if current_player == null:
		print("No player data to save!")
		return

	var save_data := {
		"game_version": 1,
		"player": {
			"name": current_player.player_name,
			"age": current_player.age,
			"nationality": current_player.nationality,
			"height_cm": current_player.height_cm,
			"weight_kg": current_player.weight_kg,
			"preferred_foot": current_player.preferred_foot,
			"pace": current_player.pace,
			"shooting": current_player.shooting,
			"passing": current_player.passing,
			"dribbling": current_player.dribbling,
			"defending": current_player.defending,
			"physical": current_player.physical,
			"goalkeeping": current_player.goalkeeping,
			"composure": current_player.composure,
			"decisions": current_player.decisions,
			"vision": current_player.vision,
			"work_rate": current_player.work_rate,
			"determination": current_player.determination,
			"positioning": current_player.positioning
		}
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved successfully!")
	else:
		print("Failed to save game!")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found!")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file:
		var data = JSON.parse_string(file.get_as_text())
		file.close()

		if data != null:
			var player_data = data["player"]

			print("Game loaded successfully!")
			print("Player Name: ", player_data["name"])
			print("Age: ", player_data["age"])
			print("Nationality: ", player_data["nationality"])
			print("Height: ", player_data["height_cm"])
			print("Weight: ", player_data["weight_kg"])
		else:
			print("Save file is corrupted!")
