%% Do not edit this file; it is auto-generated from LSR http://lsr.dsi.unimi.it
%% This file is in the public domain.
\version "2.11.61"

\header {
  lsrtags = "rhythms"

 doctitlees = "Uso de ligaduras en los arpegios"
 texidoces = "
En ocasiones se usan ligaduras de unión para escribir los arpegios.
En este caso, las dos notas ligadas no tienen que ser consecutivas.
Esto se puede conseguir estableciendo la propiedad
@code{tieWaitForNote} al valor \"verdadero\".  La misma funcionalidad
es de utilidad, por ejemplo, para ligar un trémolo a un acorde, pero
en principio, también se puede usar para notas normales consecutivas,
como se muestra en este ejemplo.

"
  texidoc = "
Ties are sometimes used to write out arpeggios.  In this case, two tied
notes need not be consecutive.  This can be achieved by setting the
@code{tieWaitForNote} property to \"true\".  The same feature is also
useful, for example, to tie a tremolo to a chord, but in principle, it
can also be used for ordinary consecutive notes, as demonstrated in
this example. 

"
  doctitle = "Using ties with arpeggios"
} % begin verbatim
\relative c' {
  \set tieWaitForNote = ##t
  \grace { c16[~ e~ g]~ } <c, e g>2
  \repeat tremolo 8 { c32~ c'~ } <c c,>1
  e8~ c~ a~ f~ <e' c a f>2
  \tieUp c8~ a \tieDown \tieDotted g~ c g2
}
