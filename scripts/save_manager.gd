extends Node

const SAVE_PATH := "user://career_save.json"
const SAVE_VERSION := 4
const SAVE_VERSION := 5

var current_player: PlayerData
var career_time: CareerTime = CareerTime.new()


func begin_new_career() -> bool:
	if current_player == null or not current_player.is_valid():
		return false
	career_time = CareerTime.new()
	if not career_time.initialize_new_career(current_player.age):
		return false
	var birth_date := CareerTime.get_birth_date_for_age(career_time.start_date, current_player.age)
	return current_player.set_birth_date(birth_date)


func sync_player_age_with_career_time() -> bool:
	if current_player == null or not current_player.has_birth_date() or not career_time.is_initialized():
		return false
	var calculated_age := CareerTime.calculate_age_on_date(career_time.current_date, current_player.get_birth_date())
	if calculated_age < PlayerData.MIN_CREATION_AGE or calculated_age > PlayerData.MAX_CAREER_AGE:
		return false
	current_player.age = calculated_age
	return true


func save_game() -> bool:
	if current_player == null:
		push_error("Cannot save invalid player data.")
		return false
	if not career_time.is_initialized():
		career_time = CareerTime.new()
		if not career_time.initialize_new_career(current_player.age):
			return false
	if not current_player.has_birth_date():
		var birth_date := CareerTime.get_birth_date_for_age(career_time.start_date, current_player.age)
		if not current_player.set_birth_date(birth_date):
			return false
	if not sync_player_age_with_career_time() or not current_player.is_valid():
		push_error("Cannot save invalid player data.")
		return false
	if current_player.current_environment == null or not current_player.current_environment.is_valid():
		push_error("Cannot save a player without a valid starting environment.")
		return false
	if not current_player.training_focus.is_empty() and not TrainingSystem.is_valid_focus(current_player.training_focus):
		push_error("Cannot save an invalid training focus.")
		return false
	if (
		current_player.last_development_event != null
		and not TrainingSystem.is_valid_result(current_player.last_development_event)
	):
		push_error("Cannot save an invalid development result.")
		return false

	var save_data := {
		"game_version": SAVE_VERSION,
		"career_time": career_time.to_save_data(),
		"player": {
			"name": current_player.player_name,
			"age": current_player.age,
			"birth_year": current_player.birth_year,
			"birth_month": current_player.birth_month,
			"birth_day": current_player.birth_day,
			"current_environment": current_player.current_environment.to_save_data(),
			"training_focus": current_player.training_focus,
			"last_development_event": (
				current_player.last_development_event.to_save_data()
				if current_player.last_development_event != null
				else {}
			),
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
		loaded_player.training_focus = saved_player["training_focus"]
		var saved_development_event: Variant = saved_player["last_development_event"]
		if typeof(saved_development_event) == TYPE_DICTIONARY and not saved_development_event.is_empty():
			loaded_player.last_development_event = DevelopmentEvent.from_save_data(saved_development_event)
			if loaded_player.last_development_event == null:
				return false
		if not loaded_player.training_focus.is_empty() and not TrainingSystem.is_valid_focus(loaded_player.training_focus):
			return false
		if loaded_player.last_development_event != null and not TrainingSystem.is_valid_result(loaded_player.last_development_event):
			return false
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
	loaded_player.birth_year = int(saved_player["birth_year"])
	loaded_player.birth_month = int(saved_player["birth_month"])
	loaded_player.birth_day = int(saved_player["birth_day"])
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

	var loaded_career_time := CareerTime.new()
	var saved_career_time: Variant = migrated_data.get("career_time")
	if typeof(saved_career_time) != TYPE_DICTIONARY:
		return false
	if not loaded_career_time.restore_from_data(saved_career_time):
		return false
	var loaded_age := CareerTime.calculate_age_on_date(
		loaded_career_time.current_date,
		loaded_player.get_birth_date()
	)
	if loaded_age < PlayerData.MIN_CREATION_AGE or loaded_age > PlayerData.MAX_CAREER_AGE:
		return false
	loaded_player.age = loaded_age

	var source_version := int(migrated_data.get("_source_version", SAVE_VERSION))
	if saved_player.has("current_environment"):
		var saved_environment: Variant = saved_player["current_environment"]
		if typeof(saved_environment) != TYPE_DICTIONARY:
			return false
		loaded_player.current_environment = CareerEnvironment.from_save_data(saved_environment)
		if loaded_player.current_environment == null:
			return false
	else:
		if source_version >= SAVE_VERSION:
			return false
		var environment_generator := StartingEnvironmentGenerator.new()
		var legacy_seed := StartingEnvironmentGenerator.legacy_seed_for_player(loaded_player)
		loaded_player.current_environment = environment_generator.generate_for_player(loaded_player, legacy_seed)
		if loaded_player.current_environment == null:
			return false
	if not loaded_player.is_valid():
		return false

	current_player = loaded_player
	career_time = loaded_career_time
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

	if version_number <= 2:
		var saved_player: Variant = migrated_data.get("player")
		if typeof(saved_player) != TYPE_DICTIONARY or not _is_integer_value(saved_player.get("age")):
			return {}
		var legacy_age := int(saved_player["age"])
		var birth_date := CareerTime.get_birth_date_for_age(CareerTime.DEFAULT_START_DATE, legacy_age)
		if birth_date.is_empty():
			return {}
		saved_player["birth_year"] = birth_date["year"]
		saved_player["birth_month"] = birth_date["month"]
		saved_player["birth_day"] = birth_date["day"]
		var default_career_time := CareerTime.new()
		if not default_career_time.initialize_new_career(legacy_age):
			return {}
		migrated_data["career_time"] = default_career_time.to_save_data()
	if version_number <= 4:
		var saved_player: Variant = migrated_data.get("player")
		if typeof(saved_player) != TYPE_DICTIONARY:
			return {}
		saved_player["training_focus"] = ""
		saved_player["last_development_event"] = {}

	migrated_data["_source_version"] = version_number
	migrated_data["game_version"] = SAVE_VERSION

	return migrated_data


func _has_valid_player_fields(saved_player: Dictionary) -> bool:
	var required_fields := [
		"name", "age", "birth_year", "birth_month", "birth_day", "training_focus",
		"last_development_event", "nationality",
		"height_cm", "weight_kg", "preferred_foot",
		"pace", "shooting", "passing", "dribbling", "defending", "physical", "goalkeeping",
		"composure", "decisions", "vision", "work_rate", "determination", "positioning",
		"potential_min", "potential_max"
	]
	for field in required_fields:
		if not saved_player.has(field):
			return false

	for field in ["name", "nationality", "preferred_foot", "training_focus"]:
		if typeof(saved_player[field]) != TYPE_STRING:
			return false
	var development_event: Variant = saved_player["last_development_event"]
	if typeof(development_event) != TYPE_DICTIONARY and typeof(development_event) != TYPE_NIL:
		return false

	var numeric_fields := [
		"age", "birth_year", "birth_month", "birth_day", "height_cm", "weight_kg",
		"pace", "shooting", "passing", "dribbling",
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
