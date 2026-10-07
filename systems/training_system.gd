extends RefCounted
class_name TrainingSystem

const MAX_RANDOM_SEED := 2147483647
const BASE_IMPROVEMENT_CHANCE := 0.34
const AGE_DEVELOPMENT_CURVE := [
	{"age": 14, "factor": 1.0},
	{"age": 18, "factor": 0.9},
	{"age": 23, "factor": 0.72},
	{"age": 28, "factor": 0.5},
	{"age": 35, "factor": 0.25},
	{"age": 45, "factor": 0.05}
]
const FOCUS_DEFINITIONS := [
	{"id": "pace", "category": "technical", "attribute": "pace"},
	{"id": "shooting", "category": "technical", "attribute": "shooting"},
	{"id": "passing", "category": "technical", "attribute": "passing"},
	{"id": "dribbling", "category": "technical", "attribute": "dribbling"},
	{"id": "defending", "category": "technical", "attribute": "defending"},
	{"id": "physical", "category": "technical", "attribute": "physical"},
	{"id": "composure", "category": "mental", "attribute": "composure"},
	{"id": "decisions", "category": "mental", "attribute": "decisions"},
	{"id": "vision", "category": "mental", "attribute": "vision"},
	{"id": "work_rate", "category": "mental", "attribute": "work_rate"},
	{"id": "determination", "category": "mental", "attribute": "determination"},
	{"id": "positioning", "category": "mental", "attribute": "positioning"},
	{"id": "goalkeeping", "category": "goalkeeping", "attribute": "goalkeeping"}
]


static func get_focus_definitions() -> Array[Dictionary]:
	return FOCUS_DEFINITIONS.duplicate(true)


static func is_valid_focus(focus_id: String) -> bool:
	return _get_focus_definition(focus_id).size() > 0


static func get_attribute_id(focus_id: String) -> String:
	return str(_get_focus_definition(focus_id).get("attribute", ""))


static func get_attribute_value(player: PlayerData, focus_id: String) -> int:
	var attribute_id := get_attribute_id(focus_id)
	if player == null or attribute_id.is_empty():
		return 0
	return int(player.get(attribute_id))


static func is_valid_result(result: DevelopmentEvent) -> bool:
	if result == null or not result.is_valid() or not is_valid_focus(result.focus_id):
		return false
	return get_attribute_id(result.focus_id) == result.affected_attribute


func process_session(
	player: PlayerData,
	focus_id: String,
	event_date: Dictionary,
	seed: int = -1
) -> DevelopmentEvent:
	if player == null or not player.is_valid() or not CareerTime.is_valid_date(event_date):
		return null
	if seed < -1 or seed > MAX_RANDOM_SEED:
		return null
	var focus := _get_focus_definition(focus_id)
	if focus.is_empty():
		return null

	var attribute_id: String = focus["attribute"]
	var previous_value := int(player.get(attribute_id))
	if previous_value < 1 or previous_value > 100:
		return null

	var random_generator := RandomNumberGenerator.new()
	var result_seed := seed
	if result_seed < 0:
		random_generator.randomize()
		result_seed = random_generator.randi_range(0, MAX_RANDOM_SEED)
	random_generator.seed = result_seed

	var outcome := "no_change"
	var change := 0
	if previous_value >= 100:
		outcome = "attribute_cap"
	elif _get_average_attribute(player) >= player.potential_max:
		outcome = "potential_ceiling"
	else:
		var chance := _get_improvement_chance(player, previous_value)
		if random_generator.randf() < chance:
			change = 1
			outcome = "improved"

	var new_value := previous_value + change
	if new_value < 1 or new_value > 100:
		return null
	player.set(attribute_id, new_value)
	player.training_focus = focus_id

	var result := DevelopmentEvent.new()
	result.focus_id = focus_id
	result.affected_attribute = attribute_id
	result.change = change
	result.previous_value = previous_value
	result.new_value = new_value
	result.event_date = event_date.duplicate(true)
	result.outcome = outcome
	result.random_seed = result_seed
	if not result.is_valid():
		return null
	player.last_development_event = result
	return result


func _get_improvement_chance(player: PlayerData, attribute_value: int) -> float:
	var potential_span := maxi(1, player.potential_max - player.potential_min)
	var remaining_potential_room := float(player.potential_max) - _get_average_attribute(player)
	var potential_factor := clampf(remaining_potential_room / float(potential_span + 20), 0.15, 1.0)
	var mental_average := float(player.determination + player.work_rate) / 2.0
	var mental_factor := 0.9 + mental_average / 500.0
	var environment_quality := 50
	if player.current_environment != null and player.current_environment.is_valid():
		environment_quality = player.current_environment.club.development_quality
	var environment_factor := 0.85 + float(environment_quality) / 100.0 * 0.3
	var attribute_factor := clampf(float(100 - attribute_value) / 30.0, 0.1, 1.0)
	var age_factor := _get_age_factor(player.age)
	return clampf(
		BASE_IMPROVEMENT_CHANCE
		* potential_factor
		* mental_factor
		* environment_factor
		* attribute_factor
		* age_factor,
		0.0,
		0.5
	)


func _get_average_attribute(player: PlayerData) -> float:
	var total := 0.0
	for focus in FOCUS_DEFINITIONS:
		total += float(player.get(focus["attribute"]))
	return total / float(FOCUS_DEFINITIONS.size())


func _get_age_factor(age: int) -> float:
	if age <= int(AGE_DEVELOPMENT_CURVE[0]["age"]):
		return float(AGE_DEVELOPMENT_CURVE[0]["factor"])
	for index in range(1, AGE_DEVELOPMENT_CURVE.size()):
		var upper_point: Dictionary = AGE_DEVELOPMENT_CURVE[index]
		if age <= int(upper_point["age"]):
			var lower_point: Dictionary = AGE_DEVELOPMENT_CURVE[index - 1]
			var age_range := float(int(upper_point["age"]) - int(lower_point["age"]))
			var progress := float(age - int(lower_point["age"])) / age_range
			return lerpf(float(lower_point["factor"]), float(upper_point["factor"]), progress)
	return float(AGE_DEVELOPMENT_CURVE[-1]["factor"])


static func _get_focus_definition(focus_id: String) -> Dictionary:
	for focus in FOCUS_DEFINITIONS:
		if focus["id"] == focus_id:
			return focus
	return {}