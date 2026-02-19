extends Node
class_name BeatmapLoader

static func load_beatmap(path: String) -> BeatmapData:
	if not FileAccess.file_exists(path):
		push_error("Beatmap file not found: " + path)
		return null
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("JSON Parse Error: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return null
		
	var data_dict = json.data
	if typeof(data_dict) != TYPE_DICTIONARY:
		push_error("Beatmap JSON root must be a dictionary")
		return null
		
	var beatmap = BeatmapData.new()
	beatmap.parse_json(data_dict)
	return beatmap
