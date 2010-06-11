% Do not edit this file; it is automatically
% generated from Documentation/snippets/new
% This file is in the public domain.
%% Note: this file works from version 2.13.11
\version "2.13.20"

\header {
%% Translation of GIT committish: e0aa246e0ed1a86dc41a99ab79bff822d3320aa7
  texidoces = "

Las cabezas de nota de notación fácil utilizan la propiedad
@code{note-names} del objeto @code{NoteHead} para determinad lo que
aparece dentro de la cabeza.  Mediante la sobreescritura de esta
propiedad, es posible imprimir números que representen el grado de la
escala.

Se puede crear un grabador simple que haga esto para la cabeza de cada
nota que ve.

"

  doctitlees = "Números como notas de notación fácil"

  lsrtags = "pitches"
  texidoc = "
Easy notation note heads use the @code{note-names} property
of the @code{NoteHead} object to determine what appears inside
the note head.  By overriding this property, it is possible
to print numbers representing the scale-degree.

A simple engraver can be created to do this for every note head
object it sees.
"
  doctitle = "Numbers as easy note heads"
} % begin verbatim


#(define Ez_numbers_engraver
   (list
    (cons 'acknowledgers
          (list
           (cons 'note-head-interface
                 (lambda (engraver grob source-engraver)
                   (let* ((context (ly:translator-context engraver))
                          (tonic-pitch (ly:context-property context 'tonic))
                          (tonic-name (ly:pitch-notename tonic-pitch))
                          (grob-pitch
                           (ly:event-property (event-cause grob) 'pitch))
                          (grob-name (ly:pitch-notename grob-pitch))
                          (delta (modulo (- grob-name tonic-name) 7))
                          (note-names
                           (make-vector 7 (number->string (1+ delta)))))
                     (ly:grob-set-property! grob 'note-names note-names))))))))

#(set-global-staff-size 26)

\layout {
  ragged-right = ##t
  \context {
    \Voice
    \consists \Ez_numbers_engraver
  }
}

\relative c' {
  \easyHeadsOn
  c4 d e f
  g4 a b c \break

  \key a \major
  a,4 b cis d
  e4 fis gis a \break

  \key d \dorian
  d,4 e f g
  a4 b c d
}
