\version "2.18.62"
\header {

    texidoc = "The property @code{chordSemanticsNameExceptions} can used
    to store a list of special notations for specific chords
    entered in chord mode."

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
	     c1:m7 g:m7
    	     \set chordSemanticsNameExceptions = #chExceptions
    	     c1:m7 g:m7
	 }
    }
}