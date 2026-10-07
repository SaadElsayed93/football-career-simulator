extends RefCounted
class_name SelectionSystem

const DEVELOPMENT_STAGE_AGES := {"youth_end": 18, "senior_transition": 21}
const TRUST_REFERENCE := 50.0
const TRUST_EFFECT := 0.12


static func evaluate(
	player: PlayerData,
	position_profile: Dictionary = {},
	manager_trust: float = TRUST_REFERENCE
) -> Dictionary:
	if player == null or player.current_environment == null or not player.current_environment.is_valid():
		return _empty_selection()
	if position_profile.is_empty():
		position_profile = PositionEvaluator.evaluate(player)

	var ranked_positions: Array = position_profile.get("ranked_positions", [])
	if ranked_positions.is_empty():
		return _empty_selection()

	var best_suitability := float(ranked_positions[0]["suitability"])
	var current_ability := PositionEvaluator.get_outfield_ability(player)
	if str(ranked_positions[0]["position_id"]) == "GK":
		current_ability = float(player.goalkeeping)
	var development_stage := _get_development_stage_factor(player.age)
	var trust_modifier := clampf((manager_trust - TRUST_REFERENCE) / 100.0, -0.5, 0.5) * TRUST_EFFECT
	var selection_score := clampf(
		best_suitability * 0.62 + current_ability * 0.28 + development_stage * 10.0 + trust_modifier * 10.0,
		0.0,
		100.0
	)
	var competition_reference := _get_competition_reference(player.current_environment.club)
	var status := _select_status(player.age, selection_score, competition_reference)
	var provisional_position := ""
	if not bool(position_profile.get("is_provisional", true)):
		provisional_position = str(position_profile.get("primary_position", ""))

	return {
		"status": status,
		"provisional_position": provisional_position,
		"is_estimate": true
	}


static func _empty_selection() -> Dictionary:
	return {"status": "not_selected", "provisional_position": "", "is_estimate": true}


static func _get_development_stage_factor(age: int) -> float:
	if age <= PlayerData.MIN_CREATION_AGE:
		return 1.0
	if age <= DEVELOPMENT_STAGE_AGES["youth_end"]:
		return 1.0 - float(age - PlayerData.MIN_CREATION_AGE) * 0.08
	if age <= DEVELOPMENT_STAGE_AGES["senior_transition"]:
		return 0.5
	return 0.0


static func _get_competition_reference(club: ClubData) -> float:
	return 38.0 + float(club.youth_level - 1) * 6.0 + float(club.club_level - 1) * 4.0


static func _select_status(age: int, selection_score: float, competition_reference: float) -> String:
	if age <= DEVELOPMENT_STAGE_AGES["youth_end"]:
		return "youth_squad" if selection_score >= competition_reference - 20.0 else "not_selected"
	if age <= DEVELOPMENT_STAGE_AGES["senior_transition"]:
		if selection_score >= competition_reference + 20.0:
			return "bench"
		return "youth_squad" if selection_score >= competition_reference - 17.0 else "not_selected"
	if selection_score >= competition_reference + 30.0:
		return "starter"
	if selection_score >= competition_reference + 15.0:
		return "bench"
	if selection_score >= competition_reference - 10.0:
		return "youth_squad"
	return "not_selected"