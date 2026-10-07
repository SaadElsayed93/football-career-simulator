extends Resource
class_name CareerEvent

enum Priority { NORMAL, IMPORTANT }
enum Status { SCHEDULED, COMPLETED, CANCELLED }

@export var event_id := ""
@export var event_date: Dictionary = {}
@export var event_type := "generic"
@export var title := ""
@export var priority: int = Priority.NORMAL
@export var status: int = Status.SCHEDULED
@export var metadata: Dictionary = {}


func is_valid() -> bool:
	if event_id.strip_edges().is_empty() or event_type.strip_edges().is_empty() or title.strip_edges().is_empty():
		return false
	if priority < Priority.NORMAL or priority > Priority.IMPORTANT:
		return false
	if status < Status.SCHEDULED or status > Status.CANCELLED:
		return false
	return typeof(metadata) == TYPE_DICTIONARY


func is_due_on(current_date: Dictionary) -> bool:
	if status != Status.SCHEDULED:
		return false
	if _compare_dates(event_date, current_date) <= 0:
		return true
	return false


func to_save_data() -> Dictionary:
	return {
		"event_id": event_id,
		"date": event_date.duplicate(true),
		"type": event_type,
		"title": title,
		"priority": priority,
		"status": status,
		"metadata": metadata.duplicate(true)
	}


static func from_save_data(data: Dictionary) -> CareerEvent:
	var date_value: Variant = data.get("date")
	var priority_value: Variant = data.get("priority", Priority.NORMAL)
	var status_value: Variant = data.get("status", Status.SCHEDULED)
	var metadata_value: Variant = data.get("metadata", {})
	if typeof(date_value) != TYPE_DICTIONARY:
		return null
	if not _is_integer_value(priority_value) or not _is_integer_value(status_value):
		return null
	if typeof(metadata_value) != TYPE_DICTIONARY:
		return null
	if typeof(data.get("event_id")) != TYPE_STRING:
		return null
	if typeof(data.get("type")) != TYPE_STRING or typeof(data.get("title")) != TYPE_STRING:
		return null

	var event := CareerEvent.new()
	event.event_id = data["event_id"]
	event.event_date = date_value.duplicate(true)
	event.event_type = data["type"]
	event.title = data["title"]
	event.priority = int(priority_value)
	event.status = int(status_value)
	event.metadata = metadata_value.duplicate(true)
	if not event.is_valid():
		return null
	return event


static func _compare_dates(first: Dictionary, second: Dictionary) -> int:
	for field in ["year", "month", "day"]:
		var first_value := int(first.get(field, 0))
		var second_value := int(second.get(field, 0))
		if first_value != second_value:
			return -1 if first_value < second_value else 1
	return 0


static func _is_integer_value(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT or not is_finite(value):
		return false
	return floor(value) == value