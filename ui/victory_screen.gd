extends Control

@onready var title_label: Label = %SongTitle
@onready var grade_label: Label = %GradeLabel
@onready var score_label: Label = %ScoreLabel
@onready var combo_label: Label = %ComboLabel
@onready var highscore_text: Label = %NewHighscore

func setup(beatmap: BeatmapData, score: float, max_combo: int, total_notes: int) -> void:
	title_label.text = beatmap.full_name 
	
	
	score_label.text = str(round(score))
	
	
	combo_label.text = "Max Combo: %d / %d" % [max_combo, total_notes]
	
	
	grade_label.text = _get_grade(score)
	
	highscore_text.visible = false 

func _get_grade(score: float) -> String:
	if score >= 11000000: return "M" 
	if score >= 10000000: return "S" 
	if score >= 9000000: return "N"  
	if score >= 8000000: return "L"  
	if score >= 7000000: return "J"  
	return "Z" 

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene() 

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/song_selector.tscn") 
