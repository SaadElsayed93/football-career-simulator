extends RefCounted
class_name PlayerGenerator

const NATIONALITY_LABELS := {
	"Egypt": "مصر",
	"England": "إنجلترا",
	"Spain": "إسبانيا",
	"Brazil": "البرازيل",
	"France": "فرنسا",
	"Germany": "ألمانيا"
}

var _rng := RandomNumberGenerator.new()


static func get_available_nationalities() -> PackedStringArray:
	var nationalities := PackedStringArray()
	for nationality in NATIONALITY_LABELS:
		nationalities.append(nationality)
	return nationalities


static func get_nationality_display_name(nationality: String) -> String:
	return str(NATIONALITY_LABELS.get(nationality, ""))


func generate_player(player_name: String, age: int, nationality: String) -> PlayerData:
	var normalized_name := player_name.strip_edges()
	if normalized_name.is_empty():
		return null
	if age < PlayerData.MIN_CREATION_AGE or age > PlayerData.MAX_CREATION_AGE:
		return null
	if not NATIONALITY_LABELS.has(nationality):
		return null

	_rng.randomize()
	var player := PlayerData.new()
	player.player_name = normalized_name
	player.age = age
	player.nationality = nationality

	var age_offset := age - PlayerData.MIN_CREATION_AGE
	var height_mean := 168.0 + age_offset * 3.5
	player.height_cm = clampi(
		roundi(_rng.randfn(height_mean, 5.5)),
		150 + age_offset * 3,
		185 + age_offset * 4
	)
	var body_mass_index := _rng.randf_range(17.8, 22.2)
	var height_m := float(player.height_cm) / 100.0
	player.weight_kg = clampi(roundi(height_m * height_m * body_mass_index), 40, 95)

	var foot_roll := _rng.randf()
	if foot_roll < 0.75:
		player.preferred_foot = "Right"
	elif foot_roll < 0.95:
		player.preferred_foot = "Left"
	else:
		player.preferred_foot = "Both"

	var skill_mean := 39.0 + age_offset * 2.0
	player.pace = _roll_rating(skill_mean, 7.0)
	player.shooting = _roll_rating(skill_mean, 7.0)
	player.passing = _roll_rating(skill_mean, 7.0)
	player.dribbling = _roll_rating(skill_mean, 7.0)
	player.defending = _roll_rating(skill_mean, 7.0)
	player.physical = _roll_rating(skill_mean, 7.0)
	player.goalkeeping = _roll_rating(29.0 + age_offset, 8.0)

	var mental_mean := 38.0 + age_offset * 1.5
	player.composure = _roll_rating(mental_mean, 7.0)
	player.decisions = _roll_rating(mental_mean, 7.0)
	player.vision = _roll_rating(mental_mean, 7.0)
	player.work_rate = _roll_rating(mental_mean, 7.0)
	player.determination = _roll_rating(mental_mean, 7.0)
	player.positioning = _roll_rating(mental_mean, 7.0)

	player.potential_min = _rng.randi_range(48, 62)
	player.potential_max = player.potential_min + _rng.randi_range(10, 20)
	return player


func _roll_rating(mean: float, deviation: float) -> int:
	return clampi(roundi(_rng.randfn(mean, deviation)), 24, 64)