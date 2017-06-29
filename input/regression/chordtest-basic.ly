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
    	 \chords { f1 g1:m a1:m7 b1:dim c1:dim7 d1:aug e1:maj7 }
    
    }
}