% chordtest-bass.ly
% Testing semantic properties of NoteEvents in EventChords.
%
% Charles Winston


\version "2.18.62"

\header {
        title = "Chord Test Bass"
}

\new Staff {
    \new Voice {
    	 \chords { f1/g f/b f/d f/e }
    
    }
}