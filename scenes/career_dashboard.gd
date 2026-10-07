extends Control

@onready var player_panel: PanelContainer = $MarginContainer/PageContent/PlayerPanel
@onready var player_name_label: Label = $MarginContainer/PageContent/PlayerPanel/PlayerDetails/PlayerName
@onready var player_age_label: Label = $MarginContainer/PageContent/PlayerPanel/PlayerDetails/PlayerMeta/AgeGroup/PlayerAge
@onready var player_nationality_label: Label = $MarginContainer/PageContent/PlayerPanel/PlayerDetails/PlayerMeta/NationalityGroup/PlayerNationality
@onready var empty_state: Label = $MarginContainer/PageContent/EmptyState


func _ready() -> void:
	var player: PlayerData = SaveManager.current_player
	if player == null:
		player_panel.visible = false
		empty_state.visible = true
		return

	var nationality_name := PlayerGenerator.get_nationality_display_name(player.nationality)
	if nationality_name.is_empty():
		nationality_name = "غير محددة"

	player_name_label.text = player.player_name
	player_age_label.text = "%d سنة" % player.age
	player_nationality_label.text = nationality_name
	player_panel.visible = true
	empty_state.visible = false