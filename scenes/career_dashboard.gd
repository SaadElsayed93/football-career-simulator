extends Control

const UNAVAILABLE := "غير متاح بعد"
const EMPTY_STAT := "لا توجد بيانات بعد"
const QUICK_ACTIONS := ["التدريب", "المباريات", "مسيرتي", "أهدافي", "الرسائل", "الأخبار", "الإحصائيات", "الإعدادات"]

@onready var career_content: VBoxContainer = %CareerContent
@onready var no_career_state: Label = %NoCareerState
@onready var player_name_label: Label = %PlayerName
@onready var player_age_label: Label = %PlayerAge
@onready var player_nationality_label: Label = %PlayerNationality
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


func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")