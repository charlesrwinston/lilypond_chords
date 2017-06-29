% chordtest-removals.ly
% Testing semantic properties of NoteEvents in EventChords.
%
% Charles Winston


\version "2.18.62"

\header {
        title = "Chord Test Removals"
}

\new Staff {
    \new Voice {
    	 \chords { f1:13^1 f:13^1.3 f:13^1.3.5 f:13^1.3.5.7
	           f:13^1.3.5.7.9 f:13^1.3.5.7.9.13}
    
    }
}