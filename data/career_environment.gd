extends Resource
class_name CareerEnvironment

const ENVIRONMENT_TYPES := ["local_academy", "youth_team", "youth_section", "academy"]

@export var club: ClubData
@export var environment_type := ""
@export_range(0, 2147483647) var generation_seed := 0


func is_valid() -> bool:
	return (
		club != null
		and club.is_valid()
		and ENVIRONMENT_TYPES.has(environment_type)
		and generation_seed >= 0
		and generation_seed <= 2147483647
	)


func to_save_data() -> Dictionary:
	return {
		"club": club.to_save_data(),
		"environment_type": environment_type,
		"generation_seed": generation_seed
	}


static func from_save_data(data: Variant) -> CareerEnvironment:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	if typeof(data.get("environment_type")) != TYPE_STRING:
		return null
	var saved_seed: Variant = data.get("generation_seed")
	if not _is_integer_value(saved_seed):
		return null
	var club := ClubData.from_save_data(data.get("club"))
	if club == null:
		return null

	var environment := CareerEnvironment.new()
	environment.club = club
	environment.environment_type = data["environment_type"]
	environment.generation_seed = int(saved_seed)
	if not environment.is_valid():
		return null
	return environment


static func _is_integer_value(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT or not is_finite(value):
		return false
	return floor(value) == value