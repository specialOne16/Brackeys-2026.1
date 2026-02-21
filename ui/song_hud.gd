extends Control

@onready var score_label: Label = %ScoreLabel
@onready var combo_label: Label = %ComboLabel
@onready var stamina_bar: ProgressBar = %StaminaBar

func _ready() -> void:
	update_score(0)
	update_combo(0)
	update_stamina(50.0)

func update_score(score: int) -> void:
	score_label.text = str(score)

func update_combo(combo: int) -> void:
	if combo >= 3:
		combo_label.text = str(combo) + "\nCOMBO"
		combo_label.show()
	else:
		combo_label.hide()

func update_stamina(percent: float) -> void:
	stamina_bar.value = percent
	
	var sb = StyleBoxFlat.new()
	if percent > 100.0:
		sb.bg_color = Color("gold")
	elif percent < 20.0:
		sb.bg_color = Color("red")
	else:
		sb.bg_color = Color("44ff44")
	
	stamina_bar.add_theme_stylebox_override("fill", sb)
