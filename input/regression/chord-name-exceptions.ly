\version "2.16.0"
\header {

    texidoc = "The property @code{chordNameExceptions} can used
    to store a list of special notations for specific chords
    entered in note mode."

}


				% 7sus4 denoted with ^7 wahh
chExceptionMusic =  {
    <c f g bes>1-\markup { \super "7" "wahh" }}

				% add to existing exceptions.
chExceptions = #(append
		 (sequential-music-to-chord-exceptions chExceptionMusic #t)
		 ignatzekExceptions)

theMusic = \relative {
    <c f g bes>1 <g c' d' f'>
    \set chordNameExceptions = #chExceptions
    <c f g bes>1 <g c' d' f'>
}

\layout { ragged-right = ##t }

<< \context ChordNames \theMusic
   \context Voice \theMusic
>>  
