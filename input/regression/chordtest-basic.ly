% chordtest-basic.ly
% Testing semantic properties of NoteEvents in EventChords.
%
% Charles Winston


\version "2.18.62"

\header {
        title = "Chord Test Basic"
}

\new Staff {
    \new Voice {
         #(display "\nNO MODS\n")
    	 \displayMusic \chords { f1 }

	 #(display "\nSIMPLE MODS\n")
	 #(display "Minor:\n")
   	 \displayMusic \chords { f1:m }
	 #(display "Minor 7:\n")
    	 \displayMusic \chords { f1:m7 }
	 #(display "Diminished:\n")
    	 \displayMusic \chords { f1:dim }
	 #(display "Diminished 7:\n")
    	 \displayMusic \chords { f1:dim7 }
         #(display "Augmented:\n")
    	 \displayMusic \chords { f1:aug }
	 #(display "Major 7:\n")
    	 \displayMusic \chords { f1:maj7 }
    
    }
}