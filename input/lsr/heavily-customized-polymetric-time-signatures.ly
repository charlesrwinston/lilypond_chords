%% Do not edit this file; it is auto-generated from LSR http://lsr.dsi.unimi.it
%% This file is in the public domain.
\version "2.11.61"

\header {
  lsrtags = "rhythms, percussion"

  texidoc = "
Though the polymetric time signature shown was not the most essential
item here, it has been included to show the beat of this piece (which
is the template of a real Balkan song!).

"
  doctitle = "Heavily customized polymetric time signatures"
} % begin verbatim
#(define (set-time-signature one two three four five six seven eight nine ten
          eleven num)
          (markup #:override '(baseline-skip . 0) #:number
          (#:line ((#:column (one num)) #:vcenter "+" (#:column (two num))
          #:vcenter "+" (#:column (three num)) #:vcenter "+" (#:column (four num))
          #:vcenter "+" (#:column (five num)) #:vcenter "+" (#:column (six num))
          #:vcenter "+" (#:column (seven num)) #:vcenter "+" (#:column (eight num))
          #:vcenter "+" (#:column (nine num)) #:vcenter "+" (#:column (ten num))
          #:vcenter "+" (#:column (eleven num))))
          ))


melody = \relative c'' {
  \set Staff.instrumentName = #"Bb Sop."
  \key g \major
  \time 25/8
  \override Staff.TimeSignature #'stencil = #ly:text-interface::print
  \override Staff.TimeSignature #'text = #(set-time-signature "3" "2" "2" "3"
    "2" "2" "2" "2" "3" "2" "2" "8" )
  \set Staff.beatGrouping = #'(3 2 2 3 2 2 2 2 3 2 2)
  #(override-auto-beam-setting '(end * * 25 8) 3 8)
  #(override-auto-beam-setting '(end * * 25 8) 5 8)
  #(override-auto-beam-setting '(end * * 25 8) 7 8)
  #(override-auto-beam-setting '(end * * 25 8) 10 8)
  #(override-auto-beam-setting '(end * * 25 8) 12 8)
  #(override-auto-beam-setting '(end * * 25 8) 14 8)
  #(override-auto-beam-setting '(end * * 25 8) 16 8)
  #(override-auto-beam-setting '(end * * 25 8) 18 8)
  #(override-auto-beam-setting '(end * * 25 8) 21 8)
  #(override-auto-beam-setting '(end * * 25 8) 23 8)

  c8 c c d4 c8 c b c b a4 g fis8 e d c b' c d e4-^ fis8 g \break
  c,4. d4 c4 d4. c4 d c2 d4. e4-^ d4
  c4. d4 c4 d4. c4 d c2 d4. e4-^ d4 \break
  c4. d4 c4 d4. c4 d c2 d4. e4-^ d4
  c4. d4 c4 d4. c4 d c2 d4. e4-^ d4 \break
}

drum = \new DrumStaff \drummode {
  \bar "|:" bd4.^\markup { "Drums" } sn4 bd \bar ":" sn4.
  bd4 sn \bar ":" bd sn bd4. sn4 bd \bar ":|"
}

{
  \melody
  \drum
}
