% chordtest-inversions.ly
% Testing semantic properties of NoteEvents in EventChords.
%
% Charles Winston


\version "2.18.62"

\header {
        title = "Chord Test Inversions"
}

\new Staff {
    \new Voice {
         #(display "\nINVERSIONS:\n")
    	 \displayMusic \chordmode { f1/c f/a f/f' }
    
    }
}