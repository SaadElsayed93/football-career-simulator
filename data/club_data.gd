extends Resource
class_name ClubData

@export var club_id := ""
@export var club_name := ""
@export var country := ""
@export_range(0, 100) var reputation := 0
@export_range(1, 3) var club_level := 1
@export_range(1, 3) var youth_level := 1
@export_range(1, 3) var financial_strength := 1
@export_range(1, 100) var development_quality := 1


func is_valid() -> bool:
	return (
		not club_id.strip_edges().is_empty()
		and not club_name.strip_edges().is_empty()
		and not country.strip_edges().is_empty()
		and reputation >= 0
		and reputation <= 100
		and club_level >= 1
		and club_level <= 3
		and youth_level >= 1
		and youth_level <= 3
		and financial_strength >= 1
		and financial_strength <= 3
		and development_quality >= 1
		and development_quality <= 100
	)


func to_save_data() -> Dictionary:
	return {
		"club_id": club_id,
		"club_name": club_name,
		"country": country,
		"reputation": reputation,
		"club_level": club_level,
		"youth_level": youth_level,
		"financial_strength": financial_strength,
		"development_quality": development_quality
	}


static func from_save_data(data: Variant) -> ClubData:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	for field in ["club_id", "club_name", "country"]:
		if typeof(data.get(field)) != TYPE_STRING:
			return null
	for field in ["reputation", "club_level", "youth_level", "financial_strength", "development_quality"]:
		if not _is_integer_value(data.get(field)):
			return null

	var club := ClubData.new()
	club.club_id = data["club_id"]
	club.club_name = data["club_name"]
	club.country = data["country"]
	club.reputation = int(data["reputation"])
	club.club_level = int(data["club_level"])
	club.youth_level = int(data["youth_level"])
	club.financial_strength = int(data["financial_strength"])
	club.development_quality = int(data["development_quality"])
	if not club.is_valid():
		return null
	return club


static func _is_integer_value(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT or not is_finite(value):
		return false
	return floor(value) == value