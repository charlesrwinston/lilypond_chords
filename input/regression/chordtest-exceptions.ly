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


%#(begin (display "chordVar\n")
%	(display chordVar) (newline)
%	(display "markupVar\n")
%	(display markupVar) (newline)
%	(display "chord-to-exceptions\n")
%	(display (chordmode-to-exceptions chordVar markupVar)))

#(chordmode-to-exceptions chordVar markupVar)

% Convert music to list, prepend to previous exceptions
% chExceptions = #(cons (chordmode-to-exceptions chordVar markupVar) semanticsExceptions)

\new Staff {
    \new Voice {
    	 \chords {
	     c1:m7
    	     %\set chordNameExceptions = #chExceptions
    	     %c1:m7
	 }
    }
}