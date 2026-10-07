extends Resource
class_name PlayerData

@export var player_name: String = ""
@export var age: int = 14
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
var potential_min: int = 60
var potential_max: int = 85
