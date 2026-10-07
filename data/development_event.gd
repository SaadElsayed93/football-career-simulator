extends Resource
class_name DevelopmentEvent

const OUTCOMES := ["improved", "no_change", "attribute_cap", "potential_ceiling"]

@export var focus_id := ""
@export var affected_attribute := ""
@export var change := 0
@export var previous_value := 0
@export var new_value := 0
@export var event_date: Dictionary = {}
@export var outcome := ""
@export_range(0, 2147483647) var random_seed := 0


func is_valid() -> bool:
	if focus_id.is_empty() or affected_attribute.is_empty() or not OUTCOMES.has(outcome):
		return false
	if change < 0 or change > 1:
		return false
	if previous_value < 1 or previous_value > 100 or new_value < 1 or new_value > 100:
		return false
	if (outcome == "improved" and change != 1) or (outcome != "improved" and change != 0):
		return false
	if new_value != previous_value + change or random_seed < 0 or random_seed > 2147483647:
		return false
	return CareerTime.is_valid_date(event_date)


func to_save_data() -> Dictionary:
	return {
		"focus_id": focus_id,
		"affected_attribute": affected_attribute,
		"change": change,
		"previous_value": previous_value,
		"new_value": new_value,
		"event_date": event_date.duplicate(true),
		"outcome": outcome,
		"random_seed": random_seed
	}


static func from_save_data(data: Variant) -> DevelopmentEvent:
	if typeof(data) != TYPE_DICTIONARY:
		return null
	for field in ["focus_id", "affected_attribute", "outcome"]:
		if typeof(data.get(field)) != TYPE_STRING:
			return null
	for field in ["change", "previous_value", "new_value", "random_seed"]:
		if not _is_integer_value(data.get(field)):
			return null
	if typeof(data.get("event_date")) != TYPE_DICTIONARY:
		return null

	var event := DevelopmentEvent.new()
	event.focus_id = data["focus_id"]
	event.affected_attribute = data["affected_attribute"]
	event.change = int(data["change"])
	event.previous_value = int(data["previous_value"])
	event.new_value = int(data["new_value"])
	event.event_date = data["event_date"].duplicate(true)
	event.outcome = data["outcome"]
	event.random_seed = int(data["random_seed"])
	if not event.is_valid():
		return null
	return event


static func _is_integer_value(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT or not is_finite(value):
		return false
	return floor(value) == value