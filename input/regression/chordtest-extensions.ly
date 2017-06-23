% chordtest-extensions.ly
% Testing semantic properties of NoteEvents in EventChords.
%
% Charles Winston


\version "2.18.62"

\header {
        title = "Chord Test Extensions"
}

\new Staff {
    \new Voice {
         #(display "\nNO MODS\n")
    	 \displayMusic \chordmode { f1 f:2 f:3 f:4 f:5
	                            f:6 f:7 f:8 f:9 f:10
				    f:11 f:12 f:13 }

	 #(display "\nSIMPLE MODS\n")
	 #(display "Minor:\n")
    	 \displayMusic \chordmode { f1:m f:m2 f:m3 f:m4 f:m5
	                            f:m6 f:m7 f:m8 f:m9 f:m10
				    f:m11 f:m12 f:m13 }
	 #(display "Diminished:\n")
    	 \displayMusic \chordmode { f1:dim f:dim2 f:dim3 f:dim4 f:dim5
	                            f:dim6 f:dim7 f:dim8 f:dim9 f:dim10
				    f:dim11 f:dim12 f:dim13 }
         #(display "Augmented:\n")
    	 \displayMusic \chordmode { f1:aug f:aug2 f:aug3 f:aug4 f:aug5
	                            f:aug6 f:aug7 f:aug8 f:aug9 f:aug10
				    f:aug11 f:aug12 f:aug13 }
	 #(display "Major 7:\n")
    	 \displayMusic \chordmode { f1:maj f:maj2 f:maj3 f:maj4 f:maj5
	                            f:maj6 f:maj7 f:maj8 f:maj9 f:maj10
				    f:maj11 f:maj12 f:maj13 }
    
    }
}