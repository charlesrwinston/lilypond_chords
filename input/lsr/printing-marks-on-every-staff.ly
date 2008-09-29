%% Do not edit this file; it is auto-generated from LSR http://lsr.dsi.unimi.it
%% This file is in the public domain.
\version "2.11.61"

\header {
  lsrtags = "text"

  texidoc = "
Although text marks are normally only printed above the topmost staff,
they may also be printed on every staff.

"
  doctitle = "Printing marks on every staff"
} % begin verbatim
{
  \new Score \with {
    \remove "Mark_engraver"
  }
  <<
    \new Staff \with {
      \consists "Mark_engraver"
    }
    { c''1 \mark "molto" c'' }
    \new Staff \with {
      \consists "Mark_engraver"
    }
    { c'1 \mark "molto" c' }
  >>
}
