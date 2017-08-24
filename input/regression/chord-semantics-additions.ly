\version "2.18.62"

\header {
        title = "Chord Semantics Additions"
}

\new Staff {
    \new Voice {
	 \new ChordNames {
	      \set additionalPitchPrefix = #"add"
	      \chordmode { c1:7 f:7.13 g:6.9 }
	 }
    }
}