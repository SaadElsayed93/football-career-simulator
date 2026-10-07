extends Resource
class_name PlayerData

const MIN_CREATION_AGE := 14
const MAX_CREATION_AGE := 16
const MAX_CAREER_AGE := 100

@export var player_name: String = ""
@export_range(14, 100) var age: int = 14
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
