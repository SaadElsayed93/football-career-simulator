extends Control

@onready var name_input: LineEdit = %LineEdit
@onready var nationality_input: OptionButton = %OptionButton
@onready var age_input: SpinBox = %SpinBox
@onready var error_label: Label = %ErrorLabel

var player_generator := PlayerGenerator.new()


func _ready() -> void:
	nationality_input.add_item("اختر الجنسية")
	nationality_input.set_item_metadata(0, "")
	for nationality in PlayerGenerator.get_available_nationalities():
		nationality_input.add_item(PlayerGenerator.get_nationality_display_name(nationality))
		nationality_input.set_item_metadata(nationality_input.item_count - 1, nationality)
	nationality_input.select(0)


func _on_create_player_button_pressed() -> void:
	error_label.visible = false
	var player_name := name_input.text.strip_edges()
	if player_name.is_empty():
		_show_error("يرجى إدخال اسم اللاعب.")
		return

	var nationality_index := nationality_input.selected
	if nationality_index <= 0:
		_show_error("يرجى اختيار الجنسية.")
		return

	var age_value := age_input.value
	var age := int(age_value)
	if (
		not is_equal_approx(age_value, float(age))
		or age < PlayerData.MIN_CREATION_AGE
		or age > PlayerData.MAX_CREATION_AGE
	):
		_show_error("يجب أن يكون العمر بين 14 و16 سنة.")
		return

	var nationality_value: Variant = nationality_input.get_item_metadata(nationality_index)
	if typeof(nationality_value) != TYPE_STRING or nationality_value.is_empty():
		_show_error("يرجى اختيار الجنسية.")
		return

	var player: PlayerData = player_generator.generate_player(player_name, age, nationality_value)
	if player == null or not player.is_valid():
		_show_error("تعذر إنشاء بيانات اللاعب. تحقق من المعلومات وحاول مرة أخرى.")
		return

	SaveManager.current_player = player
	if not SaveManager.begin_new_career():
		_show_error("تعذر تهيئة زمن المسيرة.")
		return
	if not SaveManager.save_game():
		_show_error("تعذر حفظ المسيرة. تحقق من مساحة التخزين وحاول مجددًا.")
		return

	var scene_change_error := get_tree().change_scene_to_file("res://scenes/CareerDashboard.tscn")
	if scene_change_error != OK:
		_show_error("تعذر فتح لوحة المسيرة.")


func _show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true
