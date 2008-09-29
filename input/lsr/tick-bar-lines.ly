%% Do not edit this file; it is auto-generated from LSR http://lsr.dsi.unimi.it
%% This file is in the public domain.
\version "2.11.61"

\header {
  lsrtags = "staff-notation"

  texidoc = "
'Tick' bar lines are often used in music where the bar line is used
only for coordination and is not meant to imply any rhythmic stress.

This snippet uses overrides for the @code{'bar-size} and
@code{'extra-offset} properties of @code{BarLine} to
determine, respectively, the tick size and its vertical placement.

"
  doctitle = "Tick bar lines"
} % begin verbatim
{
  % Use 'bar-size to control the height of the tick,
  % and 'extra-offset to determine its position.
  %
  % With 'extra-offset set to zero, the tick will be
  % centered around the middle line of the staff.
  %
  % Replace Staff.BarLine with Score.BarLine to
  % apply the method to the whole score.
  
  \override Staff.BarLine #'bar-size = #1
  \override Staff.BarLine #'extra-offset = #'(0 . 2)
  
  c'4 d' e' f'
  g'4 f' e' d'
  c'4 d' e' f'
  g'4 f' e' d'
  
  % Revert the overrides to get back a normal
  % bar line at the end.
  
  \revert Staff.BarLine #'bar-size
  \revert Staff.BarLine #'extra-offset
  \bar "|."
}
