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
         #(display "\nADDITIONS:\n")
    	 \displayMusic \chordmode { f1:7 f:7.2 f:7.3 f:7.4 f:7.5
	                            f:7.6 f:7.8 f:7.9 f:7.10
				    f:7.11 f:7.12 f:7.13 }
    
    }
}