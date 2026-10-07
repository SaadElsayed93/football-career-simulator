extends RefCounted
class_name TrainingLabels

const FOCUS_NAMES := {
	"pace": "السرعة",
	"shooting": "التسديد",
	"passing": "التمرير",
	"dribbling": "المراوغة",
	"defending": "الدفاع",
	"physical": "الجانب البدني",
	"composure": "الهدوء",
	"decisions": "اتخاذ القرار",
	"vision": "الرؤية",
	"work_rate": "معدل العمل",
	"determination": "العزيمة",
	"positioning": "التمركز",
	"goalkeeping": "حراسة المرمى"
}
const CATEGORY_NAMES := {
	"technical": "فني",
	"mental": "ذهني",
	"goalkeeping": "حراسة المرمى"
}


static func get_focus_name(focus_id: String) -> String:
	return str(FOCUS_NAMES.get(focus_id, "غير متاح بعد"))


static func get_category_name(category_id: String) -> String:
	return str(CATEGORY_NAMES.get(category_id, ""))


static func get_option_label(focus_id: String, category_id: String) -> String:
	var focus_name := get_focus_name(focus_id)
	var category_name := get_category_name(category_id)
	if category_name.is_empty() or category_id == "goalkeeping":
		return focus_name
	return "%s | %s" % [category_name, focus_name]


static func get_result_feedback(event: DevelopmentEvent) -> String:
	if event == null:
		return "لا توجد جلسة تدريب مسجلة بعد."
	if event.outcome == "improved":
		return "تحسن طفيف في %s." % get_focus_name(event.affected_attribute)
	if event.outcome == "attribute_cap":
		return "وصلت هذه المهارة إلى الحد الأعلى المتاح."
	return "لم يظهر تغير ملحوظ هذه المرة."