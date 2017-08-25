\version "2.18.62"

\header {
        title = "Chord Semantics Lowercase Root"
}

\new Staff {
    \new Voice {
    	 \chords {
	     c1:m f:m7 g:m13
	     \set chordNameLowercaseMinor = ##t
	     c1:m f:m7 g:m13
	 }
    
    }
}