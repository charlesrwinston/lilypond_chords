%% Do not edit this file; it is automatically
%% generated from LSR http://lsr.dsi.unimi.it
%% This file is in the public domain.
\version "2.13.20"

\header {
  lsrtags = "rhythms, vocal-music"

  texidoc = "
The @code{s} syntax for skips is only available in note mode and chord
mode. In other situations, for example, when entering lyrics, using the
@code{\\skip} command is recommended.

"
  doctitle = "Skips in lyric mode"
} % begin verbatim

<<
  \relative c'' { a1 | a }
  \new Lyrics \lyricmode { \skip 1 bla1 }
>>

