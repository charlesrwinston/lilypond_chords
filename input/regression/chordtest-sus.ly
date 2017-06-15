% chordtest-sus.ly
% Testing semantic properties of NoteEvents in EventChords.
%
% Charles Winston


\version "2.18.62"

\header {
        title = "Chord Test Sus"
}

\new Staff {
    \new Voice {
         #(display "\nSUS:\n")
	 #(display "\nNATURALS:\n")
	 \displayMusic \chordmode { f1:sus f:sus2 f:sus4 f:sus2.4 }
    }
}