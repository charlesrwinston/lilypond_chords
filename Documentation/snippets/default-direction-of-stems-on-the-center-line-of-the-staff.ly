%% DO NOT EDIT this file manually; it is automatically
%% generated from LSR http://lsr.dsi.unimi.it
%% Make any changes in LSR itself, or in Documentation/snippets/new/ ,
%% and then run scripts/auxiliar/makelsr.py
%%
%% This file is in the public domain.
\version "2.14.0"

\header {
  lsrtags = "editorial-annotations"

%% Translation of GIT committish: 8b93de6ce951b7b14bc7818f31019524295b990f
  texidoces = "
La dirección predeterminada de las plicas sobre la tercera línea
del pentagrama está determinada por la propiedad
@code{neutral-direction} del objeto @code{Stem}.

"
  doctitlees = "Dirección predeterminada de las plicas sobre la tercera línea del pentagrama"


%% Translation of GIT committish: 0a868be38a775ecb1ef935b079000cebbc64de40
  texidocde = "
Die Richtung von Hälsen auf der mittleren Linie kann mit der @code{Stem}-Eigenschaft
@code{neutral-direction} gesetzt werden.

"
  doctitlede = "Standardrichtung für Hälse auf der Mittellinie"

  texidoc = "
The default direction of stems on the center line of the staff is set
by the @code{Stem} property @code{neutral-direction}.

"
  doctitle = "Default direction of stems on the center line of the staff"
} % begin verbatim

\relative c'' {
  a4 b c b
  \override Stem #'neutral-direction = #up
  a4 b c b
  \override Stem #'neutral-direction = #down
  a4 b c b
}

