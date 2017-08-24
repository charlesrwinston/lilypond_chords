\version "2.18.62"

\header {
        title = "Chord Semantics Removals"
}

\new Staff {
    \new Voice {
    	 \set removalPitchPrefix "no"
    	 \chords { f1:13^1 f:13^1.3 f:13^1.3.5}
    
    }
}