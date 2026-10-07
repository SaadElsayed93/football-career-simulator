extends Control

const UNAVAILABLE := "غير متاح بعد"
const ARABIC_MONTH_NAMES := [
	"يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
	"يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
]

@onready var training_form: VBoxContainer = %TrainingForm
@onready var no_career_state: Label = %NoCareerState
@onready var player_name_label: Label = %PlayerName
@onready var player_age_label: Label = %PlayerAge
@onready var career_date_label: Label = %CareerDate
@onready var attribute_snapshot: HFlowContainer = %AttributeSnapshot
@onready var focus_option: OptionButton = %FocusOption
@onready var current_attribute_label: Label = %CurrentAttributeLabel
@onready var current_attribute_value: Label = %CurrentAttributeValue
@onready var start_training_button: Button = %StartTrainingButton
@onready var training_status: Label = %TrainingStatus
@onready var result_feedback: Label = %ResultFeedback
@onready var result_details: Label = %ResultDetails

var training_system := TrainingSystem.new()


func _ready() -> void:
	if SaveManager.current_player == null:
		training_form.visible = false
		no_career_state.visible = true
		return

	_populate_focus_options()
	_select_saved_focus()
	_refresh_player_snapshot()
	_refresh_attribute_snapshot()
	_refresh_selected_attribute()
	_refresh_result()


func _populate_focus_options() -> void:
	focus_option.add_item("اختر مجال التدريب")
	focus_option.set_item_metadata(0, "")
	for focus in TrainingSystem.get_focus_definitions():
		var focus_id: String = focus["id"]
		focus_option.add_item(TrainingLabels.get_option_label(focus_id, focus["category"]))
		focus_option.set_item_metadata(focus_option.item_count - 1, focus_id)
	focus_option.select(0)


func _select_saved_focus() -> void:
	var saved_focus: String = SaveManager.current_player.training_focus
	if saved_focus.is_empty():
		return
	for index in range(focus_option.item_count):
		if focus_option.get_item_metadata(index) == saved_focus:
			focus_option.select(index)
			return


func _refresh_player_snapshot() -> void:
	var player: PlayerData = SaveManager.current_player
	player_name_label.text = player.player_name
	player_age_label.text = "%d سنة" % player.age
	career_date_label.text = _format_date(SaveManager.career_time.get_current_date())


func _refresh_attribute_snapshot() -> void:
	for child in attribute_snapshot.get_children():
		child.queue_free()
	var player: PlayerData = SaveManager.current_player
	for focus in TrainingSystem.get_focus_definitions():
		var focus_id: String = focus["id"]
		var attribute_card := VBoxContainer.new()
		attribute_card.custom_minimum_size = Vector2(128, 54)
		attribute_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var attribute_name := Label.new()
		attribute_name.text = TrainingLabels.get_focus_name(focus_id)
		attribute_name.theme_type_variation = &"Caption"
		attribute_card.add_child(attribute_name)

		var attribute_value := Label.new()
		attribute_value.text = str(TrainingSystem.get_attribute_value(player, focus_id))
		attribute_value.theme_type_variation = &"SectionTitle"
		attribute_card.add_child(attribute_value)
		attribute_snapshot.add_child(attribute_card)


func _refresh_selected_attribute() -> void:
	var focus_id := _get_selected_focus_id()
	if focus_id.is_empty():
		current_attribute_label.text = "المهارة المستهدفة"
		current_attribute_value.text = UNAVAILABLE
		start_training_button.disabled = true
		return

	var attribute_value := TrainingSystem.get_attribute_value(SaveManager.current_player, focus_id)
	current_attribute_label.text = TrainingLabels.get_focus_name(focus_id)
	current_attribute_value.text = "%s: %d" % [TrainingLabels.get_focus_name(focus_id), attribute_value]
	start_training_button.disabled = false


func _refresh_result() -> void:
	var event: DevelopmentEvent = SaveManager.current_player.last_development_event
	result_feedback.text = TrainingLabels.get_result_feedback(event)
	if event == null:
		result_details.text = ""
		return
	result_details.text = "القيمة السابقة: %d، القيمة الحالية: %d\nتاريخ الجلسة: %s" % [
		event.previous_value,
		event.new_value,
		_format_date(event.event_date)
	]


func _get_selected_focus_id() -> String:
	var selected_index := focus_option.selected
	if selected_index < 0:
		return ""
	var focus_value: Variant = focus_option.get_item_metadata(selected_index)
	return focus_value if typeof(focus_value) == TYPE_STRING else ""


func _format_date(date: Dictionary) -> String:
	if not CareerTime.is_valid_date(date):
		return UNAVAILABLE
	var month_index := int(date["month"]) - 1
	return "%d %s %d" % [date["day"], ARABIC_MONTH_NAMES[month_index], date["year"]]


func _on_focus_selected(_index: int) -> void:
	_refresh_selected_attribute()
	var focus_id := _get_selected_focus_id()
	SaveManager.current_player.training_focus = focus_id
	if SaveManager.save_game():
		training_status.visible = false
	else:
		_show_status("تعذر حفظ التركيز التدريبي.")


func _on_start_training_pressed() -> void:
	var player: PlayerData = SaveManager.current_player
	var focus_id := _get_selected_focus_id()
	if player == null or not TrainingSystem.is_valid_focus(focus_id):
		_show_status("يرجى اختيار مجال تدريب صالح.")
		return

	if not SaveManager.career_time.advance_one_day(player.get_birth_date()):
		if SaveManager.career_time.get_blocking_event() != null:
			_show_status("هناك حدث مهم يتطلب الانتباه قبل مواصلة الوقت.")
		elif player.age >= PlayerData.MAX_CAREER_AGE:
			_show_status("وصل اللاعب إلى الحد العمري المتاح.")
		else:
			_show_status("تعذر بدء جلسة التدريب اليوم.")
		return

	if SaveManager.career_time.get_blocking_event() != null:
		if SaveManager.sync_player_age_with_career_time():
			_refresh_player_snapshot()
			SaveManager.save_game()
		_show_status("وصلت المسيرة إلى حدث مهم؛ لم تُنفذ جلسة التدريب.")
		return

	if not SaveManager.sync_player_age_with_career_time():
		_show_status("تعذر تحديث عمر اللاعب.")
		return

	var event := training_system.process_session(
		player,
		focus_id,
		SaveManager.career_time.get_current_date()
	)
	if event == null:
		SaveManager.save_game()
		_show_status("تعذر احتساب نتيجة التدريب.")
		return

	_refresh_player_snapshot()
	_refresh_attribute_snapshot()
	_refresh_selected_attribute()
	_refresh_result()
	if SaveManager.save_game():
		training_status.visible = false
	else:
		_show_status("تم التدريب، لكن تعذر حفظ التغيير.")


func _show_status(message: String) -> void:
	training_status.text = message
	training_status.visible = true


func _on_back_to_dashboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CareerDashboard.tscn")