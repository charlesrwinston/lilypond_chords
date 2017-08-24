\version "2.16.0"
\header {

    texidoc = "The property @code{chordNameExceptions} can used
    to store a list of special notations for specific chords
    entered in note mode or chord mode. Use
    sequential-music-to-chord-exceptions to convert to note mode
    entered exceptions. And use chordmode->exception-entry to
    convert to chord mode entered exceptions."

}

% Note mode
				% 7sus4 denoted with ^7 wahh
noteModeExceptionMusic =  {
    <c f g bes>1-\markup { \super "7" "wahh" }}

				% add to existing exceptions.
chExceptions = #(append
		 (sequential-music-to-chord-exceptions noteModeExceptionMusic #t)
		 ignatzekExceptions)

% Chord mode

chordVar = \chordmode { c1:m7 }
markupVar = \markup { \super "min7" }

% Convert music to exception pair, prepend to previous exceptions
chExceptions = #(append (chordmode->exception-entry chordVar markupVar) chExceptions)


theMusic = \relative {
    <c f g bes>1 <g c d f> \chordmode { c:m7 g:m7 }
    \set chordNameExceptions = #chExceptions
    <c f g bes>1 <g c d f> \chordmode { c:m7 g:m7 }
}

\layout { ragged-right = ##t }

<< \context ChordNames \theMusic
   \context Voice \theMusic
>>  
