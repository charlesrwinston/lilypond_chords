% chordtest-basic.ly
% Testing semantic properties of NoteEvents in EventChords.
%
% Charles Winston


\version "2.18.62"

\header {
        title = "Chord Test Exceptions"
}

% Event Chord
chordVar = \chordmode { c1:m7 }

% Markup
markupVar = \markup { \super "min7" }

% Convert music to list, prepend to previous exceptions
chExceptions = #(append (chordmode->exception-entry chordVar markupVar) semanticExceptions)

\new Staff {
    \new Voice {
    	 \chords {
	     c1:m7
    	     \set chordSemanticsNameExceptions = #chExceptions
    	     c1:m7
	 }
    }
}