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
         #(display "\nALTERATIONS\n")
    	 \displayMusic \chordmode { f1:13 f:13.2+ f:13.2- f:13.3+ f:13.3-
	                            f:13.4+ f:13.4- f:13.5+ f:13.5- f:6+ f:6-
				    f:13.7+ f:13.7- f:13.8+ f:13.8- f:13.9+ f:13.9-
				    f:13.10+ f:13.10- f:13.11+ f:13.11-
				    f:13.12+ f:13.12- f:13.13+ f13.13- }
    
    }
}