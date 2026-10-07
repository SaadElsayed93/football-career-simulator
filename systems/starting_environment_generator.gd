extends RefCounted
class_name StartingEnvironmentGenerator

const MAX_SEED := 2147483647
const COUNTRY_PROFILES := {
	"Egypt": {
		"id": "egypt",
		"ecosystem_strength": 48,
		"places": [
			{"id": "nile", "label": "النيل"},
			{"id": "cairo", "label": "القاهرة"},
			{"id": "alexandria", "label": "الإسكندرية"},
			{"id": "delta", "label": "الدلتا"}
		]
	},
	"England": {
		"id": "england",
		"ecosystem_strength": 76,
		"places": [
			{"id": "london", "label": "لندن"},
			{"id": "manchester", "label": "مانشستر"},
			{"id": "yorkshire", "label": "يوركشاير"},
			{"id": "bristol", "label": "بريستول"}
		]
	},
	"Spain": {
		"id": "spain",
		"ecosystem_strength": 74,
		"places": [
			{"id": "madrid", "label": "مدريد"},
			{"id": "valencia", "label": "فالنسيا"},
			{"id": "sevilla", "label": "إشبيلية"},
			{"id": "bilbao", "label": "بلباو"}
		]
	},
	"Brazil": {
		"id": "brazil",
		"ecosystem_strength": 72,
		"places": [
			{"id": "sao_paulo", "label": "ساو باولو"},
			{"id": "rio", "label": "ريو"},
			{"id": "santos", "label": "سانتوس"},
			{"id": "minas", "label": "ميناس"}
		]
	},
	"France": {
		"id": "france",
		"ecosystem_strength": 73,
		"places": [
			{"id": "paris", "label": "باريس"},
			{"id": "lyon", "label": "ليون"},
			{"id": "marseille", "label": "مارسيليا"},
			{"id": "nantes", "label": "نانت"}
		]
	},
	"Germany": {
		"id": "germany",
		"ecosystem_strength": 75,
		"places": [
			{"id": "berlin", "label": "برلين"},
			{"id": "munich", "label": "ميونخ"},
			{"id": "hamburg", "label": "هامبورغ"},
			{"id": "dortmund", "label": "دورتموند"}
		]
	}
}
const DEFAULT_COUNTRY_PROFILE := {
	"id": "local",
	"ecosystem_strength": 50,
	"places": [{"id": "community", "label": "المدينة"}]
}
const CLUB_ARCHETYPES := [
	{
		"id": "local_academy",
		"environment_type": "local_academy",
		"name_format": "أكاديمية %s المحلية",
		"club_level": 1,
		"youth_level": 1,
		"financial_strength": 1,
		"reputation_min": 18,
		"reputation_max": 36,
		"development_min": 32,
		"development_max": 42,
		"target_quality": 37
	},
	{
		"id": "youth_team",
		"environment_type": "youth_team",
		"name_format": "نادي %s للشباب",
		"club_level": 1,
		"youth_level": 1,
		"financial_strength": 1,
		"reputation_min": 25,
		"reputation_max": 42,
		"development_min": 39,
		"development_max": 49,
		"target_quality": 44
	},
	{
		"id": "youth_section",
		"environment_type": "youth_section",
		"name_format": "نادي %s لقطاع الناشئين",
		"club_level": 2,
		"youth_level": 2,
		"financial_strength": 2,
		"reputation_min": 38,
		"reputation_max": 58,
		"development_min": 48,
		"development_max": 59,
		"target_quality": 54
	},
	{
		"id": "established_academy",
		"environment_type": "academy",
		"name_format": "أكاديمية %s للناشئين",
		"club_level": 3,
		"youth_level": 3,
		"financial_strength": 2,
		"reputation_min": 55,
		"reputation_max": 73,
		"development_min": 64,
		"development_max": 76,
		"target_quality": 69
	}
]


func generate_for_player(player: PlayerData, seed: int = -1) -> CareerEnvironment:
	if player == null or not player.is_valid() or seed < -1 or seed > MAX_SEED:
		return null

	var rng := RandomNumberGenerator.new()
	var generation_seed := seed
	if generation_seed < 0:
		rng.randomize()
		generation_seed = rng.randi_range(0, MAX_SEED)
	rng.seed = generation_seed

	var country_profile: Dictionary = COUNTRY_PROFILES.get(player.nationality, DEFAULT_COUNTRY_PROFILE)
	var places: Array = country_profile["places"]
	var candidates: Array[Dictionary] = []
	var weights: Array[float] = []
	var total_weight := 0.0
	var access_score := _get_access_score(player, int(country_profile["ecosystem_strength"]))

	for archetype in CLUB_ARCHETYPES:
		var place: Dictionary = places[rng.randi_range(0, places.size() - 1)]
		var club := _create_club(
			player.nationality,
			country_profile,
			place,
			archetype,
			generation_seed,
			rng
		)
		var candidate := {
			"club": club,
			"environment_type": archetype["environment_type"]
		}
		var weight := maxf(1.0, 50.0 - absf(access_score - float(club.development_quality)) * 1.5)
		candidates.append(candidate)
		weights.append(weight)
		total_weight += weight

	var selection_roll := rng.randf_range(0.0, total_weight)
	var selected_index := candidates.size() - 1
	for index in range(weights.size()):
		selection_roll -= weights[index]
		if selection_roll <= 0.0:
			selected_index = index
			break

	var selected: Dictionary = candidates[selected_index]
	var environment := CareerEnvironment.new()
	environment.club = selected["club"]
	environment.environment_type = selected["environment_type"]
	environment.generation_seed = generation_seed
	if not environment.is_valid():
		return null
	return environment


static func legacy_seed_for_player(player: PlayerData) -> int:
	var seed_text := "%s|%s|%d|%d|%d|%d|%d|%d|%d|%d|%d|%d" % [
		player.player_name,
		player.nationality,
		player.age,
		player.pace,
		player.shooting,
		player.passing,
		player.dribbling,
		player.defending,
		player.physical,
		player.potential_min,
		player.potential_max,
		player.height_cm
	]
	var stable_seed := 17
	for byte_value in seed_text.to_utf8_buffer():
		stable_seed = (stable_seed * 31 + int(byte_value)) % (MAX_SEED + 1)
	return stable_seed


func _get_access_score(player: PlayerData, ecosystem_strength: int) -> float:
	var ability_score := float(
		player.pace + player.shooting + player.passing + player.dribbling + player.defending + player.physical
	) / 6.0
	var potential_midpoint := float(player.potential_min + player.potential_max) / 2.0
	return (
		48.0
		+ float(ecosystem_strength - 50) * 0.35
		+ (ability_score - 40.0) * 0.45
		+ (potential_midpoint - 65.0) * 0.12
		+ float(player.age - PlayerData.MIN_CREATION_AGE) * 1.2
	)


func _create_club(
	country: String,
	country_profile: Dictionary,
	place: Dictionary,
	archetype: Dictionary,
	generation_seed: int,
	rng: RandomNumberGenerator
) -> ClubData:
	var club := ClubData.new()
	club.club_id = "%s_%s_%s_%d" % [
		country_profile["id"],
		place["id"],
		archetype["id"],
		generation_seed
	]
	club.club_name = str(archetype["name_format"]) % place["label"]
	club.country = country
	club.reputation = rng.randi_range(archetype["reputation_min"], archetype["reputation_max"])
	club.club_level = archetype["club_level"]
	club.youth_level = archetype["youth_level"]
	club.financial_strength = archetype["financial_strength"]
	club.development_quality = rng.randi_range(archetype["development_min"], archetype["development_max"])
	return club