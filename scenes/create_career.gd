extends Control


@onready var name_input: LineEdit = $LineEdit
@onready var nationality_input: OptionButton = $OptionButton
@onready var age_input: SpinBox = $SpinBox


func _ready() -> void:
	nationality_input.add_item("Egypt")
	nationality_input.add_item("England")
	nationality_input.add_item("Spain")
	nationality_input.add_item("Brazil")
	nationality_input.add_item("France")
	nationality_input.add_item("Germany")


func _on_create_player_button_pressed() -> void:
	var player := PlayerData.new()

	player.player_name = name_input.text
	player.age = int(age_input.value)
	player.nationality = nationality_input.get_item_text(nationality_input.selected)

	SaveManager.current_player = player
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/CareerDashboard.tscn")

	print("Player created!")
	print("Name: ", player.player_name)
	print("Age: ", player.age)
	print("Nationality: ", player.nationality)
