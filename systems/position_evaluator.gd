extends RefCounted
class_name PositionEvaluator

const MIN_GOALKEEPER_ABILITY := 50
const GOALKEEPER_ADVANTAGE := 12
const MIN_PRIMARY_SUITABILITY := 45.0
const MIN_PRIMARY_LEAD := 4.0
const TOP_POSITION_COUNT := 3
const POSITION_PROFILES := [
	{
		"id": "GK",
		"weights": {
			"goalkeeping": 45.0,
			"positioning": 12.0,
			"composure": 10.0,
			"decisions": 10.0,
			"physical": 8.0,
			"vision": 5.0
		}
	},
	{
		"id": "CB",
		"weights": {
			"defending": 24.0,
			"positioning": 20.0,
			"physical": 18.0,
			"decisions": 14.0,
			"composure": 12.0,
			"pace": 12.0
		}
	},
	{
		"id": "LB",
		"weights": {
			"pace": 20.0,
			"defending": 18.0,
			"passing": 16.0,
			"physical": 14.0,
			"work_rate": 12.0,
			"dribbling": 10.0,
			"positioning": 10.0
		}
	},
	{
		"id": "RB",
		"weights": {
			"pace": 20.0,
			"defending": 18.0,
			"passing": 16.0,
			"physical": 14.0,
			"work_rate": 12.0,
			"dribbling": 10.0,
			"positioning": 10.0
		}
	},
	{
		"id": "CDM",
		"weights": {
			"defending": 20.0,
			"passing": 18.0,
			"positioning": 16.0,
			"decisions": 16.0,
			"work_rate": 12.0,
			"physical": 10.0,
			"composure": 8.0
		}
	},
	{
		"id": "CM",
		"weights": {
			"passing": 22.0,
			"vision": 18.0,
			"decisions": 18.0,
			"work_rate": 14.0,
			"physical": 10.0,
			"positioning": 10.0,
			"composure": 8.0
		}
	},
	{
		"id": "CAM",
		"weights": {
			"passing": 20.0,
			"vision": 22.0,
			"decisions": 18.0,
			"dribbling": 16.0,
			"composure": 10.0,
			"shooting": 8.0,
			"positioning": 6.0
		}
	},
	{
		"id": "LW",
		"weights": {
			"pace": 22.0,
			"dribbling": 22.0,
			"passing": 12.0,
			"shooting": 14.0,
			"work_rate": 10.0,
			"decisions": 10.0,
			"positioning": 10.0
		}
	},
	{
		"id": "RW",
		"weights": {
			"pace": 22.0,
			"dribbling": 22.0,
			"passing": 12.0,
			"shooting": 14.0,
			"work_rate": 10.0,
			"decisions": 10.0,
			"positioning": 10.0
		}
	},
	{
		"id": "ST",
		"weights": {
			"shooting": 24.0,
			"positioning": 20.0,
			"composure": 16.0,
			"physical": 14.0,
			"pace": 14.0,
			"decisions": 12.0
		}
	}
]
const OUTFIELD_ATTRIBUTES := [
	"pace", "shooting", "passing", "dribbling", "defending", "physical",
	"composure", "decisions", "vision", "work_rate", "determination", "positioning"
]


static func evaluate(player: PlayerData) -> Dictionary:
	if player == null:
		return _empty_profile()

	var outfield_average := get_outfield_ability(player)
	var ranked_positions: Array[Dictionary] = []
	for position_profile in POSITION_PROFILES:
		var position_id: String = position_profile["id"]
		if position_id == "GK" and not _is_goalkeeper_candidate(player, outfield_average):
			continue
		ranked_positions.append({
			"position_id": position_id,
			"suitability": _calculate_suitability(player, position_profile)
		})
	ranked_positions.sort_custom(_sort_by_suitability)

	if ranked_positions.is_empty():
		return _empty_profile()

	var top_score := float(ranked_positions[0]["suitability"])
	var second_score := float(ranked_positions[1]["suitability"]) if ranked_positions.size() > 1 else 0.0
	var has_clear_primary := (
		player.age >= PlayerData.MIN_CREATION_AGE + 2
		and top_score >= MIN_PRIMARY_SUITABILITY
		and top_score - second_score >= MIN_PRIMARY_LEAD
	)
	var primary_position := str(ranked_positions[0]["position_id"]) if has_clear_primary else ""
	var secondary_positions: Array[String] = []
	var developing_positions: Array[String] = []
	for index in range(mini(TOP_POSITION_COUNT, ranked_positions.size())):
		var position_id: String = ranked_positions[index]["position_id"]
		if position_id != primary_position:
			secondary_positions.append(position_id)
		if player.age <= PlayerData.MIN_CREATION_AGE + 2 or float(ranked_positions[index]["suitability"]) >= top_score - 8.0:
			developing_positions.append(position_id)

	return {
		"ranked_positions": ranked_positions,
		"primary_position": primary_position,
		"secondary_positions": secondary_positions,
		"developing_positions": developing_positions,
		"is_provisional": not has_clear_primary
	}


static func _empty_profile() -> Dictionary:
	return {
		"ranked_positions": [],
		"primary_position": "",
		"secondary_positions": [],
		"developing_positions": [],
		"is_provisional": true
	}


static func _is_goalkeeper_candidate(player: PlayerData, outfield_average: float) -> bool:
	return (
		player.goalkeeping >= MIN_GOALKEEPER_ABILITY
		and float(player.goalkeeping) >= outfield_average + GOALKEEPER_ADVANTAGE
	)


static func _calculate_suitability(player: PlayerData, position_profile: Dictionary) -> float:
	var weights: Dictionary = position_profile["weights"]
	var weighted_total := 0.0
	var total_weight := 0.0
	for attribute_id in weights:
		var weight := float(weights[attribute_id])
		weighted_total += float(player.get(attribute_id)) * weight
		total_weight += weight
	var weighted_average := weighted_total / total_weight
	if position_profile["id"] == "GK":
		return clampf(weighted_average, 0.0, 100.0)
	var foot_modifier := _get_foot_modifier(player, str(position_profile["id"]))
	return clampf(weighted_average * 0.82 + get_outfield_ability(player) * 0.18 + foot_modifier, 0.0, 100.0)


static func get_outfield_ability(player: PlayerData) -> float:
	var total := 0.0
	for attribute_id in OUTFIELD_ATTRIBUTES:
		total += float(player.get(attribute_id))
	return total / float(OUTFIELD_ATTRIBUTES.size())


static func _get_foot_modifier(player: PlayerData, position_id: String) -> float:
	if position_id in ["LB", "LW"]:
		if player.preferred_foot == "Left":
			return 2.0
		if player.preferred_foot == "Right":
			return -1.0
	if position_id in ["RB", "RW"]:
		if player.preferred_foot == "Right":
			return 2.0
		if player.preferred_foot == "Left":
			return -1.0
	if player.preferred_foot == "Both" and position_id in ["LB", "LW", "RB", "RW"]:
		return 1.0
	return 0.0


static func _sort_by_suitability(first: Dictionary, second: Dictionary) -> bool:
	return float(first["suitability"]) > float(second["suitability"])