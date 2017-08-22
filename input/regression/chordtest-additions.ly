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
	 \new ChordNames {
	      \set additionalPitchPrefix = #"add"
	      \chordmode { c1:7 f:7.13.9.11 g:6.9.2.10 }
	 }
    }
}