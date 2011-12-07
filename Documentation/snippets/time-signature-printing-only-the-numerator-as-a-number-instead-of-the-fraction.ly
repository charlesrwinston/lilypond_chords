%% DO NOT EDIT this file manually; it is automatically
%% generated from LSR http://lsr.dsi.unimi.it
%% Make any changes in LSR itself, or in Documentation/snippets/new/ ,
%% and then run scripts/auxiliar/makelsr.py
%%
%% This file is in the public domain.
\version "2.14.0"

\header {
  lsrtags = "rhythms, tweaks-and-overrides"

%% Translation of GIT committish: 8b93de6ce951b7b14bc7818f31019524295b990f
  texidoces = "

A veces, la indicación de compás no debe imprimir la fracción completa
(p.ej.  7/4), sino sólo el numerador (7 en este caso).  Esto se puede
hacer fácilmente utilizando @code{\\override Staff.TimeSignature
#'style = #'single-digit} para cambiar el estilo
permanentemente. Usando @code{\\revert Staff.TimeSignature #'style},
se puede revertir el cambio.  Para aplicar el estilo de un dígito
único a una sola indicación de compás, utilice la instrucción
@code{\\override} y anteponga la instrucción @code{\\once}.

"
  doctitlees = "Indicación de compás imprimiendo sólo el numerador (en lugar de la fracción)"

%% Translation of GIT committish: 190a067275167c6dc9dd0afef683d14d392b7033

  texidocfr = "
La métrique est parfois indiquée non pas par une fraction (p.ex. 7/4)
mais simplement par son numérateur (7 dans ce cas).  L'instruction
@code{\\override Staff.TimeSignature #'style = #'single-digit} permet de
déroger au style par défaut de manière permanente -- un @code{\\revert
Staff.TimeSignature #'style} d'annuler ces modifications.  Lorsque cette
métrique sous le forme d'une seul chiffre ne se présente qu'une seule
fois, il suffit de faire précéder l'instruction @code{\\override} d'un
simple @code{\\once}.

"
  doctitlefr = "Affichage seulement du numérateur d'une métrique (au
lieu d'une fraction)"


  texidoc = "
Sometimes, a time signature should not print the whole fraction (e.g.
7/4), but only the numerator (7 in this case). This can be easily done
by using @code{\\override Staff.TimeSignature #'style = #'single-digit}
to change the style permanently. By using @code{\\revert
Staff.TimeSignature #'style}, this setting can be reversed. To apply
the single-digit style to only one time signature, use the
@code{\\override} command and prefix it with a @code{\\once}.

"
  doctitle = "Time signature printing only the numerator as a number (instead of the fraction)"
} % begin verbatim

\relative c'' {
  \time 3/4
  c4 c c
  % Change the style permanently
  \override Staff.TimeSignature #'style = #'single-digit
  \time 2/4
  c4 c
  \time 3/4
  c4 c c
  % Revert to default style:
  \revert Staff.TimeSignature #'style
  \time 2/4
  c4 c
  % single-digit style only for the next time signature
  \once \override Staff.TimeSignature #'style = #'single-digit
  \time 5/4
  c4 c c c c
  \time 2/4
  c4 c
}

