extends RefCounted
class_name PositionLabels

const POSITION_NAMES := {
	"GK": "حارس مرمى",
	"CB": "قلب دفاع",
	"LB": "ظهير أيسر",
	"RB": "ظهير أيمن",
	"CDM": "لاعب وسط دفاعي",
	"CM": "لاعب وسط",
	"CAM": "لاعب وسط هجومي",
	"LW": "جناح أيسر",
	"RW": "جناح أيمن",
	"ST": "مهاجم"
}
const SQUAD_STATUS_NAMES := {
	"not_selected": "غير مختار",
	"youth_squad": "فريق الشباب",
	"bench": "بديل",
	"starter": "أساسي"
}


static func get_position_name(position_id: String) -> String:
	return str(POSITION_NAMES.get(position_id, ""))


static func get_squad_status_name(status_id: String) -> String:
	return str(SQUAD_STATUS_NAMES.get(status_id, "غير محددة"))