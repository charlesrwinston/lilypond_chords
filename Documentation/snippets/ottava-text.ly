%% DO NOT EDIT this file manually; it is automatically
%% generated from LSR http://lsr.dsi.unimi.it
%% Make any changes in LSR itself, or in Documentation/snippets/new/ ,
%% and then run scripts/auxiliar/makelsr.py
%%
%% This file is in the public domain.
\version "2.14.0"

\header {
  lsrtags = "pitches, text"

%% Translation of GIT committish: 8b93de6ce951b7b14bc7818f31019524295b990f
  texidoces = "

Internamente, @code{\\ottava} establece las propiedades
@code{ottavation} (por ejemplo, a @code{8va} o a @code{8vb}) y
@code{middleCPosition}.  Para sobreescribir el texto del corchete,
ajuste @code{ottavation} después de invocar la instrucción
@code{\\ottava}.

"

  doctitlees = "Texto de octava alta y baja"


%% Translation of GIT committish: 0a868be38a775ecb1ef935b079000cebbc64de40
texidocde = "
Intern setzt die @code{set-octavation}-Funktion die Eigenschaften
@code{ottavation} (etwa auf den Wert @code{\"8va\"} oder @code{\"8vb\"})
und @code{middleCPosition}.  Um den Text der Oktavierungsklammer zu
ändern, kann @code{ottavation} manuell gesetzt werden, nachdem
@code{set-octavation} benützt wurde.

"

doctitlede = "Ottava-Text"

%% Translation of GIT committish: 58a29969da425eaf424946f4119e601545fb7a7e
  texidocfr = "
En interne, la fonction @code{\\ottava} détermine les
propriétés @code{ottavation} (p.ex. en @code{\"8va\"} ou @code{\"8vb\"})
et @code{centralCPosition}.  Vous pouvez modifier le texte d'une marque
d'octaviation en définissant @code{ottavation} après avoir fait appel
à @code{ottava} :

"

  doctitlefr = "Texte des marques d'octaviation"


  texidoc = "
Internally, @code{\\ottava} sets the properties @code{ottavation} (for
example, to @code{8va} or @code{8vb}) and @code{middleCPosition}.  To
override the text of the bracket, set @code{ottavation} after invoking
@code{\\ottava}.

"
  doctitle = "Ottava text"
} % begin verbatim

{
  \ottava #1
  \set Staff.ottavation = #"8"
  c''1
  \ottava #0
  c'1
  \ottava #1
  \set Staff.ottavation = #"Text"
  c''1
}

