extends RefCounted
class_name CareerTime

const DEFAULT_START_DATE := {"year": 2026, "month": 8, "day": 1}
const DEFAULT_SEASON_START_MONTH := 8
const MAX_ADVANCE_DAYS := 36500
const MIN_SUPPORTED_YEAR := 1
const MAX_SUPPORTED_YEAR := 9999

var current_date: Dictionary = {}
var start_date: Dictionary = {}
var season_start_month := DEFAULT_SEASON_START_MONTH
var events: Array[CareerEvent] = []


func initialize_new_career(
	initial_age: int,
	career_start_date: Dictionary = DEFAULT_START_DATE,
	configured_season_start_month: int = DEFAULT_SEASON_START_MONTH
) -> bool:
	if initial_age < 1 or initial_age > 100:
		return false
	if not is_valid_date(career_start_date):
		return false
	if configured_season_start_month < 1 or configured_season_start_month > 12:
		return false

	current_date = career_start_date.duplicate(true)
	start_date = career_start_date.duplicate(true)
	season_start_month = configured_season_start_month
	events.clear()
	return is_initialized()


func restore_from_data(data: Dictionary) -> bool:
	var restored_current_date: Variant = data.get("current_date")
	var restored_start_date: Variant = data.get("start_date")
	var restored_season_month: Variant = data.get("season_start_month")
	var restored_events: Variant = data.get("events", [])
	if typeof(restored_current_date) != TYPE_DICTIONARY:
		return false
	if typeof(restored_start_date) != TYPE_DICTIONARY:
		return false
	if not _is_integer_value(restored_season_month) or restored_season_month < 1 or restored_season_month > 12:
		return false
	if typeof(restored_events) != TYPE_ARRAY:
		return false
	if not is_valid_date(restored_current_date) or not is_valid_date(restored_start_date):
		return false
	if _compare_dates(restored_current_date, restored_start_date) < 0:
		return false

	var expected_season_year := _season_start_year_for(restored_current_date, int(restored_season_month))
	var saved_season_year: Variant = data.get("season_start_year", expected_season_year)
	if not _is_integer_value(saved_season_year) or int(saved_season_year) != expected_season_year:
		return false

	var restored_event_list: Array[CareerEvent] = []
	var seen_event_ids: Dictionary = {}
	for event_data in restored_events:
		if typeof(event_data) != TYPE_DICTIONARY:
			return false
		var event := CareerEvent.from_save_data(event_data)
		if event == null or not is_valid_date(event.event_date):
			return false
		if seen_event_ids.has(event.event_id):
			return false
		seen_event_ids[event.event_id] = true
		restored_event_list.append(event)

	current_date = restored_current_date.duplicate(true)
	start_date = restored_start_date.duplicate(true)
	season_start_month = int(restored_season_month)
	events = restored_event_list
	return true


func get_current_date() -> Dictionary:
	return current_date.duplicate(true)


func get_days_elapsed() -> int:
	if not is_initialized():
		return 0
	return _days_from_civil(current_date) - _days_from_civil(start_date)


static func calculate_age_on_date(date: Dictionary, birth_date: Dictionary) -> int:
	if not is_valid_date(date) or not is_valid_date(birth_date):
		return 0
	var age := int(date["year"]) - int(birth_date["year"])
	var anniversary_day := mini(
		int(birth_date["day"]),
		get_days_in_month(int(date["year"]), int(birth_date["month"]))
	)
	if (
		int(date["month"]) < int(birth_date["month"])
		or (
			int(date["month"]) == int(birth_date["month"])
			and int(date["day"]) < anniversary_day
		)
	):
		age -= 1
	return age


static func get_birth_date_for_age(career_start_date: Dictionary, initial_age: int) -> Dictionary:
	if not is_valid_date(career_start_date) or initial_age < 1 or initial_age > 100:
		return {}
	var birth_date := career_start_date.duplicate(true)
	birth_date["year"] = int(career_start_date["year"]) - initial_age
	if not is_valid_date(birth_date):
		return {}
	return birth_date


func get_season_start_year() -> int:
	if not is_initialized():
		return 0
	return _season_start_year_for(current_date, season_start_month)


func get_season_label() -> String:
	var season_year := get_season_start_year()
	if season_year == 0:
		return ""
	return "%d/%d" % [season_year, season_year + 1]


func advance_one_day(birth_date: Dictionary = {}) -> bool:
	return advance_days(1, birth_date) == 1


func advance_days(amount: int, birth_date: Dictionary = {}) -> int:
	if not is_initialized() or amount < 1 or amount > MAX_ADVANCE_DAYS:
		return 0
	if not birth_date.is_empty() and not is_valid_date(birth_date):
		return 0
	if get_blocking_event() != null:
		return 0

	var current_ordinal := _days_from_civil(current_date)
	var target_ordinal := current_ordinal + amount
	var target_date := _civil_from_days(target_ordinal)
	if int(target_date["year"]) > MAX_SUPPORTED_YEAR:
		return 0

	var destination_ordinal := target_ordinal
	for event in events:
		if event.status != CareerEvent.Status.SCHEDULED or event.priority != CareerEvent.Priority.IMPORTANT:
			continue
		var event_ordinal := _days_from_civil(event.event_date)
		if event_ordinal > current_ordinal and event_ordinal <= destination_ordinal:
			destination_ordinal = event_ordinal

	var destination_date := _civil_from_days(destination_ordinal)
	if not birth_date.is_empty() and calculate_age_on_date(destination_date, birth_date) > 100:
		return 0
	current_date = destination_date
	return destination_ordinal - current_ordinal


func schedule_event(event: CareerEvent) -> bool:
	if not is_initialized() or event == null or not event.is_valid():
		return false
	if not is_valid_date(event.event_date) or _compare_dates(event.event_date, current_date) < 0:
		return false
	for existing_event in events:
		if existing_event.event_id == event.event_id:
			return false
	events.append(event)
	return true


func get_due_events() -> Array[CareerEvent]:
	var due_events: Array[CareerEvent] = []
	if not is_initialized():
		return due_events
	for event in events:
		if event.is_due_on(current_date):
			due_events.append(event)
	return due_events


func get_blocking_event() -> CareerEvent:
	for event in events:
		if event.priority == CareerEvent.Priority.IMPORTANT and event.is_due_on(current_date):
			return event
	return null


func get_next_event() -> CareerEvent:
	var blocking_event := get_blocking_event()
	if blocking_event != null:
		return blocking_event
	if not is_initialized():
		return null
	var next_event: CareerEvent
	for event in events:
		if event.status != CareerEvent.Status.SCHEDULED:
			continue
		if _compare_dates(event.event_date, current_date) < 0:
			continue
		if next_event == null or _compare_dates(event.event_date, next_event.event_date) < 0:
			next_event = event
	return next_event


func get_next_important_event() -> CareerEvent:
	if not is_initialized():
		return null
	var next_event: CareerEvent
	for event in events:
		if event.status != CareerEvent.Status.SCHEDULED or event.priority != CareerEvent.Priority.IMPORTANT:
			continue
		if _compare_dates(event.event_date, current_date) <= 0:
			continue
		if next_event == null or _compare_dates(event.event_date, next_event.event_date) < 0:
			next_event = event
	return next_event


func mark_event_completed(event_id: String) -> bool:
	for event in events:
		if event.event_id == event_id and event.status == CareerEvent.Status.SCHEDULED:
			event.status = CareerEvent.Status.COMPLETED
			return true
	return false


func to_save_data() -> Dictionary:
	var saved_events: Array[Dictionary] = []
	for event in events:
		saved_events.append(event.to_save_data())
	return {
		"current_date": current_date.duplicate(true),
		"start_date": start_date.duplicate(true),
		"season_start_month": season_start_month,
		"season_start_year": get_season_start_year(),
		"events": saved_events
	}


func is_initialized() -> bool:
	return is_valid_date(current_date) and is_valid_date(start_date)


static func is_valid_date(date: Dictionary) -> bool:
	for field in ["year", "month", "day"]:
		if not date.has(field) or not _is_integer_value(date[field]):
			return false
	var year := int(date["year"])
	var month := int(date["month"])
	var day := int(date["day"])
	if year < MIN_SUPPORTED_YEAR or year > MAX_SUPPORTED_YEAR or month < 1 or month > 12:
		return false
	return day >= 1 and day <= get_days_in_month(year, month)


static func is_leap_year(year: int) -> bool:
	return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)


static func get_days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			return 29 if is_leap_year(year) else 28
	return 0


static func _season_start_year_for(date: Dictionary, configured_month: int) -> int:
	var year := int(date["year"])
	return year if int(date["month"]) >= configured_month else year - 1


static func _compare_dates(first: Dictionary, second: Dictionary) -> int:
	for field in ["year", "month", "day"]:
		var first_value := int(first[field])
		var second_value := int(second[field])
		if first_value != second_value:
			return -1 if first_value < second_value else 1
	return 0


static func _days_from_civil(date: Dictionary) -> int:
	var year := int(date["year"])
	var month := int(date["month"])
	var day := int(date["day"])
	year -= 1 if month <= 2 else 0
	var era := floori(float(year) / 400.0)
	var year_of_era := year - era * 400
	var adjusted_month := month + (-3 if month > 2 else 9)
	var day_of_year := floori(float(153 * adjusted_month + 2) / 5.0) + day - 1
	var day_of_era := year_of_era * 365 + floori(float(year_of_era) / 4.0) - floori(float(year_of_era) / 100.0) + day_of_year
	return era * 146097 + day_of_era


static func _civil_from_days(ordinal: int) -> Dictionary:
	var era := floori(float(ordinal) / 146097.0)
	var day_of_era := ordinal - era * 146097
	var year_of_era := floori(float(
		day_of_era
		- floori(float(day_of_era) / 1460.0)
		+ floori(float(day_of_era) / 36524.0)
		- floori(float(day_of_era) / 146096.0)
	) / 365.0)
	var year := year_of_era + era * 400
	var day_of_year := day_of_era - (365 * year_of_era + floori(float(year_of_era) / 4.0) - floori(float(year_of_era) / 100.0))
	var month_parameter := floori(float(5 * day_of_year + 2) / 153.0)
	var day := day_of_year - floori(float(153 * month_parameter + 2) / 5.0) + 1
	var month := month_parameter + (3 if month_parameter < 10 else -9)
	year += 1 if month <= 2 else 0
	return {"year": year, "month": month, "day": day}


static func _is_integer_value(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT or not is_finite(value):
		return false
	return floor(value) == value