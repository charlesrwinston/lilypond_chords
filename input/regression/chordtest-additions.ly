% chordtest-additions.ly
% Testing semantic properties of NoteEvents in EventChords.
%
% Charles Winston


\version "2.18.62"

\header {
        title = "Chord Test Additions"
}

\new Staff {
    \new Voice {
<<<<<<< HEAD
	 \new ChordNames {
	      \set additionalPitchPrefix = #"add"
	      \chordmode { c1:7 f:7.13.9.11 g:6.9.2.10 }
	 }
=======
	 \chords { c1:7 f:7.13.9.11 g:6.9.2.10 }
>>>>>>> 478b455960df22570cd3522d7d9c91aac5192902
    
    }
}