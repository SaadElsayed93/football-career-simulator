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
@onready var career_date_label: Label = %CareerDate
@onready var career_season_label: Label = %CareerSeason
@onready var calendar_status_label: Label = %CalendarStatus
@onready var next_event_title_label: Label = $MarginContainer/PageContent/DashboardScroll/DashboardContent/CareerContent/NextEventPanel/NextEventContent/NextEventTitle
@onready var next_event_description_label: Label = $MarginContainer/PageContent/DashboardScroll/DashboardContent/CareerContent/NextEventPanel/NextEventContent/NextEventDescription
@onready var quick_actions: HFlowContainer = $MarginContainer/PageContent/DashboardScroll/DashboardContent/CareerContent/QuickActionsPanel/QuickActionsContent/QuickActions
@onready var career_status: DashboardSection = %CareerStatus
@onready var career_snapshot: DashboardSection = %CareerSnapshot
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
	_configure_sections()
	_configure_quick_actions()
	_refresh_calendar_display()
	_refresh_next_event_display()


func _configure_sections() -> void:
	career_status.configure("حالة المسيرة", [
		{"label": "النادي الحالي", "value": UNAVAILABLE},
		{"label": "المكانة في الفريق", "value": UNAVAILABLE},
		{"label": "المركز", "value": UNAVAILABLE},
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
	recent_events.configure("أحدث الأحداث", [], "لا توجد أحداث مسجلة بعد.")


func _configure_quick_actions() -> void:
	for action_name in QUICK_ACTIONS:
		var action_button := Button.new()
		action_button.text = "%s\nغير متاح بعد" % action_name
		action_button.custom_minimum_size = Vector2(164, 76)
		action_button.theme_type_variation = &"SecondaryButton"
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