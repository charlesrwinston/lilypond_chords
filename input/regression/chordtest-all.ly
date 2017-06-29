% chordtest-all.ly
% Testing semantic properties of NoteEvents in EventChords.
%
% Charles Winston


\version "2.18.62"

\header {
        title = "Chord Test All"
}

\new Staff {
    \new Voice {
         \chords { f1:m7.9.6.13^3/c c:maj7.9.6.13^3/f }
    }
}