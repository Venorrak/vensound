extends Node

var refSheet : Dictionary[String, Array] = {
	"C": [16.35, 32.7, 65.41, 130.81, 261.63, 523.25, 1046.5, 2093.0],
	"C#": [17.32, 34.65, 69.3, 138.59, 277.18, 554.37, 1108.73, 2217.46],
	"D": [18.35, 36.71, 73.42, 146.83, 293.66, 587.33, 1174.66, 2349.32],
	"D#": [19.45, 38.89, 77.78, 155.56, 311.13, 622.25, 1244.51, 2489.0],
	"E": [20.6, 41.2, 82.41, 164.81, 329.63, 659.25, 1318.51, 2637.0],
	"F": [21.83, 43.65, 87.31, 174.61, 349.23, 698.46, 1396.91, 2793.83],
	"F#": [23.12, 46.25, 92.5, 185.0, 369.99, 739.99, 1479.98, 2959.96],
	"G": [24.5, 49.0, 98.0, 196.0, 392.0, 783.99, 1567.98, 3135.96],
	"G#": [25.96, 51.91, 103.83, 207.65, 415.3, 830.61, 1661.22, 3322.44],
	"A": [27.5, 55.0, 110.0, 220.0, 440.0, 880.0, 1760.0, 3520.0],
	"A#": [29.14, 58.27, 116.54, 233.08, 466.16, 932.33, 1864.66, 3729.31],
	"B": [30.87, 61.74, 123.47, 246.94, 493.88, 987.77, 1975.53, 3951.0]
}

func getNote(ref : String) -> float:
	var octave : int = int(ref.right(1))
	if octave >= 0 && octave < 8:
		var freq : float = refSheet[ref.trim_suffix(str(octave))][octave]
		if freq:
			return freq
	return 0.0
	
func getLine(freq : float) -> int:
	for note in refSheet.keys():
		for noteOct in refSheet[note]:
			if noteOct == freq:
				return (refSheet[note].find(noteOct) * 12) + refSheet.keys().find(note)
	return -1
	
func getFreq(line : int) -> float:
	var octave : int = line / 12
	var note : int = line % 12
	return refSheet[refSheet.keys()[note]][octave]
