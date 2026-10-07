extends Resource
class_name PlayerData

const MIN_CREATION_AGE := 14
const MAX_CREATION_AGE := 16
const MAX_CAREER_AGE := 100

@export var player_name: String = ""
@export_range(14, 100) var age: int = 14
@export var birth_year: int = 0
@export_range(0, 12) var birth_month: int = 0
@export_range(0, 31) var birth_day: int = 0
@export var nationality: String = ""
@export var height_cm: int = 175
@export var weight_kg: int = 70
@export var preferred_foot: String = "Right"
@export_category("Technical Attributes")
@export_range(1, 100) var pace: int = 50
@export_range(1, 100) var shooting: int = 50
@export_range(1, 100) var passing: int = 50
@export_range(1, 100) var dribbling: int = 50
@export_range(1, 100) var defending: int = 50
@export_range(1, 100) var physical: int = 50
@export_range(1, 100) var goalkeeping: int = 10
@export_category("Mental Attributes")
@export_range(1, 100) var composure: int = 50
@export_range(1, 100) var decisions: int = 50
@export_range(1, 100) var vision: int = 50
@export_range(1, 100) var work_rate: int = 50
@export_range(1, 100) var determination: int = 50
@export_range(1, 100) var positioning: int = 50
var potential_min: int = 50
var potential_max: int = 70


func is_valid() -> bool:
	if player_name.strip_edges().is_empty():
		return false
	if age < MIN_CREATION_AGE or age > MAX_CAREER_AGE:
		return false
	if not _is_birth_date_valid():
		return false
	if nationality.strip_edges().is_empty():
		return false
	if height_cm < 130 or height_cm > 220 or weight_kg < 35 or weight_kg > 150:
		return false
	if not ["Right", "Left", "Both"].has(preferred_foot):
		return false
	if potential_min < 1 or potential_max > 100 or potential_min > potential_max:
		return false

	for rating in [pace, shooting, passing, dribbling, defending, physical, goalkeeping,
		composure, decisions, vision, work_rate, determination, positioning]:
		if rating < 1 or rating > 100:
			return false

	return true


func has_birth_date() -> bool:
	return birth_year > 0


func set_birth_date(date: Dictionary) -> bool:
	if not CareerTime.is_valid_date(date):
		return false
	birth_year = int(date["year"])
	birth_month = int(date["month"])
	birth_day = int(date["day"])
	return true


func get_birth_date() -> Dictionary:
	if not has_birth_date():
		return {}
	return {"year": birth_year, "month": birth_month, "day": birth_day}


func _is_birth_date_valid() -> bool:
	if birth_year == 0 and birth_month == 0 and birth_day == 0:
		return true
	if birth_year < 1 or birth_year > 9999 or birth_month < 1 or birth_month > 12:
		return false
	return birth_day >= 1 and birth_day <= CareerTime.get_days_in_month(birth_year, birth_month)
