% chordtest-alterations.ly
% Testing semantic properties of NoteEvents in EventChords.
%
% Charles Winston


\version "2.18.62"

\header {
        title = "Chord Test Alterations"
}

\new Staff {
    \new Voice {
    	 \chords { f1:13 f:13.5+ f:13.7- f:13.9+ f:13.3-}
    
    }
}