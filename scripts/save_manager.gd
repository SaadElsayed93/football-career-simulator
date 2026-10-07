extends Node

const SAVE_PATH := "user://career_save.json"
const SAVE_VERSION := 2

var current_player: PlayerData


func save_game() -> bool:
	if current_player == null or not current_player.is_valid():
		push_error("Cannot save invalid player data.")
		return false

	var save_data := {
		"game_version": SAVE_VERSION,
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
			"positioning": current_player.positioning,
			"potential_min": current_player.potential_min,
			"potential_max": current_player.potential_max
		}
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open career save for writing.")
		return false

	file.store_string(JSON.stringify(save_data))
	var save_error := file.get_error()
	file.close()
	if save_error != OK:
		push_error("Failed to write career save.")
		return false

	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var parsed_data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed_data) != TYPE_DICTIONARY:
		return false

	var migrated_data := _migrate_save_data(parsed_data)
	var saved_player: Variant = migrated_data.get("player")
	if typeof(saved_player) != TYPE_DICTIONARY or not _has_valid_player_fields(saved_player):
		return false

	var loaded_player := PlayerData.new()
	loaded_player.player_name = saved_player["name"]
	loaded_player.age = int(saved_player["age"])
	loaded_player.nationality = saved_player["nationality"]
	loaded_player.height_cm = int(saved_player["height_cm"])
	loaded_player.weight_kg = int(saved_player["weight_kg"])
	loaded_player.preferred_foot = saved_player["preferred_foot"]
	loaded_player.pace = int(saved_player["pace"])
	loaded_player.shooting = int(saved_player["shooting"])
	loaded_player.passing = int(saved_player["passing"])
	loaded_player.dribbling = int(saved_player["dribbling"])
	loaded_player.defending = int(saved_player["defending"])
	loaded_player.physical = int(saved_player["physical"])
	loaded_player.goalkeeping = int(saved_player["goalkeeping"])
	loaded_player.composure = int(saved_player["composure"])
	loaded_player.decisions = int(saved_player["decisions"])
	loaded_player.vision = int(saved_player["vision"])
	loaded_player.work_rate = int(saved_player["work_rate"])
	loaded_player.determination = int(saved_player["determination"])
	loaded_player.positioning = int(saved_player["positioning"])
	loaded_player.potential_min = int(saved_player["potential_min"])
	loaded_player.potential_max = int(saved_player["potential_max"])
	if not loaded_player.is_valid():
		return false

	current_player = loaded_player
	return true


func _migrate_save_data(data: Dictionary) -> Dictionary:
	var version: Variant = data.get("game_version", 1)
	if not _is_integer_value(version):
		return {}
	var version_number := int(version)
	if version_number < 1 or version_number > SAVE_VERSION:
		return {}

	var migrated_data := data.duplicate(true)
	if version_number == 1:
		var saved_player: Variant = migrated_data.get("player")
		if typeof(saved_player) != TYPE_DICTIONARY:
			return {}
		saved_player["potential_min"] = 50
		saved_player["potential_max"] = 70
		migrated_data["game_version"] = SAVE_VERSION

	return migrated_data


func _has_valid_player_fields(saved_player: Dictionary) -> bool:
	var required_fields := [
		"name", "age", "nationality", "height_cm", "weight_kg", "preferred_foot",
		"pace", "shooting", "passing", "dribbling", "defending", "physical", "goalkeeping",
		"composure", "decisions", "vision", "work_rate", "determination", "positioning",
		"potential_min", "potential_max"
	]
	for field in required_fields:
		if not saved_player.has(field):
			return false

	for field in ["name", "nationality", "preferred_foot"]:
		if typeof(saved_player[field]) != TYPE_STRING:
			return false

	var numeric_fields := [
		"age", "height_cm", "weight_kg", "pace", "shooting", "passing", "dribbling",
		"defending", "physical", "goalkeeping", "composure", "decisions", "vision",
		"work_rate", "determination", "positioning", "potential_min", "potential_max"
	]
	for field in numeric_fields:
		if not _is_integer_value(saved_player[field]):
			return false

	return true


func _is_integer_value(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT or not is_finite(value):
		return false
	return floor(value) == value
