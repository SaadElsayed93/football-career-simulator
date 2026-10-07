extends Control

const UNAVAILABLE := "غير متاح بعد"
const EMPTY_STAT := "لا توجد بيانات بعد"
const QUICK_ACTIONS := ["التدريب", "المباريات", "مسيرتي", "أهدافي", "الرسائل", "الأخبار", "الإحصائيات", "الإعدادات"]
const ARABIC_MONTH_NAMES := [
	"يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
	"يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
]

@onready var career_content: VBoxContainer = %CareerContent
@onready var no_career_state: Label = %NoCareerState
@onready var player_name_label: Label = %PlayerName
@onready var player_age_label: Label = %PlayerAge
@onready var player_nationality_label: Label = %PlayerNationality
@onready var starting_club_name_label: Label = %StartingClubName
@onready var starting_environment_intro_label: Label = %StartingEnvironmentIntroduction
@onready var primary_position_label: Label = %PrimaryPosition
@onready var position_rows: VBoxContainer = %PositionRows
@onready var squad_status_label: Label = %SquadStatus
@onready var career_date_label: Label = %CareerDate
@onready var career_season_label: Label = %CareerSeason
@onready var calendar_status_label: Label = %CalendarStatus
@onready var next_event_title_label: Label = $MarginContainer/PageContent/DashboardScroll/DashboardContent/CareerContent/NextEventPanel/NextEventContent/NextEventTitle
@onready var next_event_description_label: Label = $MarginContainer/PageContent/DashboardScroll/DashboardContent/CareerContent/NextEventPanel/NextEventContent/NextEventDescription
@onready var quick_actions: HFlowContainer = $MarginContainer/PageContent/DashboardScroll/DashboardContent/CareerContent/QuickActionsPanel/QuickActionsContent/QuickActions
@onready var career_status: DashboardSection = %CareerStatus
@onready var career_snapshot: DashboardSection = %CareerSnapshot
@onready var development_snapshot: DashboardSection = %DevelopmentSnapshot
@onready var recent_events: DashboardSection = %RecentEvents


func _ready() -> void:
	var player: PlayerData = SaveManager.current_player
	if player == null:
		career_content.visible = false
		no_career_state.visible = true
		return

	var nationality_name := PlayerGenerator.get_nationality_display_name(player.nationality)
	if nationality_name.is_empty():
		nationality_name = UNAVAILABLE

	player_name_label.text = player.player_name
	player_age_label.text = "%d سنة" % player.age
	player_nationality_label.text = nationality_name
	var position_profile := PositionEvaluator.evaluate(player)
	var selection_profile := SelectionSystem.evaluate(player, position_profile)
	_configure_starting_environment(player)
	_configure_position_profile(position_profile, selection_profile)
	_configure_sections(player, position_profile, selection_profile)
	_configure_quick_actions()
	_refresh_calendar_display()
	_refresh_next_event_display()


func _configure_starting_environment(player: PlayerData) -> void:
	var environment := player.current_environment
	if environment == null or not environment.is_valid():
		starting_club_name_label.text = UNAVAILABLE
		starting_environment_intro_label.text = "لم يتم تحديد بيئة البداية بعد."
		return
	starting_club_name_label.text = environment.club.club_name
	starting_environment_intro_label.text = "انضممت إلى %s لتبدأ مسيرتك الكروية." % environment.club.club_name


func _configure_position_profile(position_profile: Dictionary, selection_profile: Dictionary) -> void:
	var primary_position := str(position_profile.get("primary_position", ""))
	primary_position_label.text = (
		PositionLabels.get_position_name(primary_position)
		if not primary_position.is_empty()
		else "لم يتحدد المركز بعد"
	)
	squad_status_label.text = PositionLabels.get_squad_status_name(str(selection_profile.get("status", "not_selected")))

	var ranked_positions: Array = position_profile.get("ranked_positions", [])
	for index in range(mini(3, ranked_positions.size())):
		var ranked_position: Dictionary = ranked_positions[index]
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var position_name := Label.new()
		position_name.text = PositionLabels.get_position_name(ranked_position["position_id"])
		position_name.custom_minimum_size = Vector2(144, 0)
		position_name.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(position_name)

		var suitability_bar := ProgressBar.new()
		suitability_bar.min_value = 0.0
		suitability_bar.max_value = 100.0
		suitability_bar.value = float(ranked_position["suitability"])
		suitability_bar.show_percentage = false
		suitability_bar.custom_minimum_size = Vector2(0, 18)
		suitability_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(suitability_bar)
		position_rows.add_child(row)


func _configure_sections(
	player: PlayerData,
	position_profile: Dictionary,
	selection_profile: Dictionary
) -> void:
	var club_name := UNAVAILABLE
	var environment_name := UNAVAILABLE
	var club_level_name := UNAVAILABLE
	var development_quality_name := UNAVAILABLE
	var current_position_name := "لم يتحدد المركز بعد"
	var squad_status_name := PositionLabels.get_squad_status_name(str(selection_profile.get("status", "not_selected")))
	if player.current_environment != null and player.current_environment.is_valid():
		var environment := player.current_environment
		club_name = environment.club.club_name
		environment_name = _get_environment_label(environment.environment_type)
		club_level_name = _get_club_level_label(environment.club.club_level)
		development_quality_name = _get_development_quality_label(environment.club.development_quality)
	var primary_position := str(position_profile.get("primary_position", ""))
	if not primary_position.is_empty():
		current_position_name = PositionLabels.get_position_name(primary_position)

	career_status.configure("بيئة اللاعب وحالة المسيرة", [
		{"label": "النادي", "value": club_name},
		{"label": "البيئة", "value": environment_name},
		{"label": "مستوى النادي", "value": club_level_name},
		{"label": "بيئة التطوير", "value": development_quality_name},
		{"label": "حالة الفريق", "value": squad_status_name},
		{"label": "المركز الحالي", "value": current_position_name},
		{"label": "التقييم العام", "value": UNAVAILABLE},
		{"label": "الحالة الفنية", "value": UNAVAILABLE},
		{"label": "اللياقة البدنية", "value": UNAVAILABLE},
		{"label": "الجاهزية", "value": UNAVAILABLE},
		{"label": "ثقة المدرب", "value": UNAVAILABLE}
	])
	career_snapshot.configure("ملخص المسيرة", [
		{"label": "المشاركات", "value": EMPTY_STAT},
		{"label": "المباريات الأساسية", "value": EMPTY_STAT},
		{"label": "الدقائق", "value": EMPTY_STAT},
		{"label": "الأهداف", "value": EMPTY_STAT},
		{"label": "التمريرات الحاسمة", "value": EMPTY_STAT},
		{"label": "متوسط التقييم", "value": EMPTY_STAT},
		{"label": "البطولات", "value": EMPTY_STAT},
		{"label": "الجوائز", "value": EMPTY_STAT}
	])
	var current_focus := "لم يتم الاختيار بعد"
	var last_training := EMPTY_STAT
	var last_development := EMPTY_STAT
	if not player.training_focus.is_empty():
		current_focus = TrainingLabels.get_focus_name(player.training_focus)
	if player.last_development_event != null:
		last_training = _format_date(player.last_development_event.event_date)
		last_development = TrainingLabels.get_result_feedback(player.last_development_event)
	development_snapshot.configure("التطور", [
		{"label": "التركيز الحالي", "value": current_focus},
		{"label": "آخر تدريب", "value": last_training},
		{"label": "آخر تطور", "value": last_development}
	])
	recent_events.configure("أحدث الأحداث", [], "لا توجد أحداث مسجلة بعد.")


func _get_environment_label(environment_type: String) -> String:
	match environment_type:
		"local_academy":
			return "أكاديمية محلية"
		"youth_team":
			return "فريق شباب"
		"youth_section":
			return "قطاع الناشئين"
		"academy":
			return "أكاديمية الناشئين"
	return UNAVAILABLE


func _get_club_level_label(club_level: int) -> String:
	match club_level:
		1:
			return "محلي"
		2:
			return "إقليمي"
		3:
			return "متقدم"
	return UNAVAILABLE


func _get_development_quality_label(quality: int) -> String:
	if quality >= 64:
		return "قوية"
	if quality >= 50:
		return "جيدة"
	if quality >= 40:
		return "نامية"
	return "محدودة"


func _configure_quick_actions() -> void:
	for action_name in QUICK_ACTIONS:
		var action_button := Button.new()
		action_button.custom_minimum_size = Vector2(164, 76)
		action_button.theme_type_variation = &"SecondaryButton"
		if action_name == "التدريب":
			action_button.text = action_name
			action_button.disabled = false
			action_button.pressed.connect(_on_training_pressed)
		else:
			action_button.text = "%s\nغير متاح بعد" % action_name
			action_button.disabled = true
		quick_actions.add_child(action_button)


func _refresh_calendar_display() -> void:
	var date := SaveManager.career_time.get_current_date()
	if date.is_empty():
		career_date_label.text = UNAVAILABLE
		career_season_label.text = UNAVAILABLE
		return
	career_date_label.text = _format_date(date)
	career_season_label.text = SaveManager.career_time.get_season_label()
	player_age_label.text = "%d سنة" % SaveManager.current_player.age


func _refresh_next_event_display() -> void:
	var event := SaveManager.career_time.get_next_event()
	if event == null:
		next_event_title_label.text = "لا يوجد حدث قادم حالياً"
		next_event_description_label.text = "ستظهر هنا المواعيد والأحداث المهمة عند توفر نظامها."
		return
	next_event_title_label.text = event.title
	next_event_description_label.text = "الموعد: %s" % _format_date(event.event_date)


func _format_date(date: Dictionary) -> String:
	if not CareerTime.is_valid_date(date):
		return UNAVAILABLE
	var month_index := int(date["month"]) - 1
	return "%d %s %d" % [date["day"], ARABIC_MONTH_NAMES[month_index], date["year"]]


func _on_advance_day_pressed() -> void:
	var player: PlayerData = SaveManager.current_player
	if not SaveManager.career_time.advance_one_day(player.get_birth_date()):
		if SaveManager.career_time.get_blocking_event() != null:
			calendar_status_label.text = "هناك حدث مهم يتطلب الانتباه قبل مواصلة الوقت."
		elif player.age >= PlayerData.MAX_CAREER_AGE:
			calendar_status_label.text = "وصل اللاعب إلى الحد العمري المتاح."
		else:
			calendar_status_label.text = "تعذر تقديم التاريخ أكثر."
		calendar_status_label.visible = true
		return

	if not SaveManager.sync_player_age_with_career_time():
		calendar_status_label.text = "تعذر تحديث عمر اللاعب."
		calendar_status_label.visible = true
		return

	_refresh_calendar_display()
	_refresh_next_event_display()
	if SaveManager.save_game():
		calendar_status_label.visible = false
	else:
		calendar_status_label.text = "تقدم التاريخ، لكن تعذر حفظ المسيرة."
		calendar_status_label.visible = true


func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_training_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/training_screen.tscn")
