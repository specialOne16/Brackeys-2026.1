extends Window

signal notes_generated(new_notes: Array[Dictionary])

@onready var weights_grid: GridContainer = %WeightsGrid
@onready var div_option: OptionButton = %DivOption
@onready var density_slider: HSlider = %DensitySlider
@onready var threshold_slider: HSlider = %ThresholdSlider

var _weight_sliders: Dictionary = {}
const NOTE_TYPES = ["any", "cut", "bump", "deflect", "pierce"]

# Data from the main editor
var current_audio_stream: AudioStream
var current_bpm: float = 120.0
var current_duration: float = 0.0
var grid_cols: int = 4
var grid_rows: int = 3

func _ready() -> void:
	_create_weight_sliders()

func _create_weight_sliders() -> void:
	for type in NOTE_TYPES:
		var label = Label.new()
		label.text = type.capitalize()
		
		var slider = HSlider.new()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.max_value = 10.0
		slider.value = 5.0 # Default weight
		if type == "any": slider.value = 8.0
		
		weights_grid.add_child(label)
		weights_grid.add_child(slider)
		_weight_sliders[type] = slider

func setup(stream: AudioStream, bpm: float, duration: float, cols: int, rows: int) -> void:
	current_audio_stream = stream
	current_bpm = bpm
	current_duration = duration
	grid_cols = cols
	grid_rows = rows
	popup_centered()

func _on_cancel_btn_pressed() -> void:
	hide()

func _on_generate_btn_pressed() -> void:
	if current_bpm <= 0:
		print("Invalid BPM")
		return
		
	var generated = _run_generation()
	notes_generated.emit(generated)
	hide()

func _run_generation() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	var snap_val = div_option.get_selected_id() # 1, 2, or 4
	var step_time = (60.0 / current_bpm) / float(snap_val)
	var density = density_slider.value
	var threshold = threshold_slider.value
	
	var wav_data: PackedByteArray
	var can_analyze_audio = false
	var mix_rate = 44100
	var format_bits = 16
	var stereo = false
	
	if current_audio_stream is AudioStreamWAV:
		var wav = current_audio_stream as AudioStreamWAV
		if wav.data.size() > 0:
			wav_data = wav.data
			mix_rate = wav.mix_rate
			stereo = wav.stereo
			format_bits = 8 if wav.format == AudioStreamWAV.FORMAT_8_BITS else 16
			can_analyze_audio = true
			print("Analyzing WAV data for generation...")
	
	var t = 0.0
	t += step_time 
	
	while t < current_duration:
		var place_note = false
		
		if can_analyze_audio:
			var amp = _get_amplitude_at_time(wav_data, t, mix_rate, format_bits, stereo)
			amp = clamp(amp * 2.0, 0.0, 1.0) 
			
			if amp > threshold:
				if randf() < (density + 0.2): 
					place_note = true
		else:
			if randf() < density:
				place_note = true
		
		if place_note:
			var type = _pick_weighted_type()
			var lane = randi() % grid_cols
			var row = randi() % grid_rows
			
			result.append({
				"time": t,
				"lane_x": float(lane),
				"height_y": float(row),
				"type": type
			})
		
		t += step_time
		
	return result

func _get_amplitude_at_time(data: PackedByteArray, time: float, rate: int, bits: int, is_stereo: bool) -> float:
	var frame_size = (bits / 8) * (2 if is_stereo else 1)
	var frame_idx = int(time * rate)
	var byte_idx = frame_idx * frame_size
	
	if byte_idx < 0 or byte_idx >= data.size() - frame_size:
		return 0.0
		
	var sample_val = 0.0
	
	if bits == 16:
		var b1 = data[byte_idx]
		var b2 = data[byte_idx + 1]
		var s = (b2 << 8) | b1
		if s > 32767: s -= 65536
		sample_val = abs(s / 32768.0)
	else:
		var b = data[byte_idx]
		sample_val = abs((b - 128) / 128.0)
		
	return sample_val

func _pick_weighted_type() -> String:
	var pool = []
	for type in NOTE_TYPES:
		var weight = int(_weight_sliders[type].value)
		for i in range(weight):
			pool.append(type)
	
	if pool.is_empty(): return "any"
	return pool.pick_random()
