extends PanelContainer
class_name DashboardSection

@onready var title_label: Label = %SectionTitle
@onready var entry_grid: GridContainer = %EntryGrid
@onready var empty_state: Label = %EmptyState


func _ready() -> void:
	_update_columns()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_columns()


func configure(section_title: String, entries: Array[Dictionary], empty_message: String = "") -> void:
	title_label.text = section_title
	entry_grid.visible = not entries.is_empty()
	empty_state.visible = entries.is_empty()
	empty_state.text = empty_message
	for child in entry_grid.get_children():
		child.queue_free()

	for entry in entries:
		_add_entry(str(entry.get("label", "")), str(entry.get("value", "")))


func _add_entry(caption_text: String, value_text: String) -> void:
	var item := VBoxContainer.new()
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.custom_minimum_size = Vector2(0, 64)

	var caption := Label.new()
	caption.text = caption_text
	caption.theme_type_variation = &"Caption"
	item.add_child(caption)

	var value := Label.new()
	value.text = value_text
	value.theme_type_variation = &"SectionTitle"
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_child(value)
	entry_grid.add_child(item)


func _update_columns() -> void:
	if size.x < 480.0:
		entry_grid.columns = 1
	elif size.x < 900.0:
		entry_grid.columns = 2
	else:
		entry_grid.columns = 4