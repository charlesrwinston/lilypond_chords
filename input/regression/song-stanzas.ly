\version "2.11.16"

\include "festival.ly"

\festival #"song-stanzas.xml" { \tempo 4 = 100 }
{
\time 3/4
\relative { c2 e4 g2. }
\addlyrics { play the game }
\addlyrics { speel het spel }
\addlyrics { joue le jeu }
}
#(display "song-stanzas")
#(ly:progress "~a" (ly:gulp-file "song-stanzas.xml"))
