% DO NOT EDIT this file manually; it is automatically
% generated from Documentation/snippets/new
% Make any changes in Documentation/snippets/new/
% and then run scripts/auxiliar/makelsr.py
%
% This file is in the public domain.
%% Note: this file works from version 2.14.0
\version "2.14.0"

\header {
%% Translation of GIT committish: 8b93de6ce951b7b14bc7818f31019524295b990f
  texidoces = "
No está especificada ninguna agrupación predeterminada automática
de las barras para el compás de 7/8, de forma que si se requieren
barras automáticas se debe especificar la forma de agrupamiento.
Por ejemplo, para agrupar todas las barras en la forma 2-3-2 en el
compás de 7/8, especificamos los finales de barra en 2/8 y 5/8:

"
  doctitlees = "Agrupamiento de las barras en el compás de 7/8"


%% Translation of GIT committish: 0a868be38a775ecb1ef935b079000cebbc64de40
texidocde = "
Es gibt keine automatischen Balkengruppen für 7/8-Takte.  Wenn diese
Taktart benötigt wird, müssen die Gruppierungen definiert werden.  Um
beispielsweise alle Noten in 2/8-3/8-2/8 aufzuteilen, müssen Balkenenden
für 2/8 und 5/8 definiert werden:

"
  doctitlede = "Balkengruppen für 7/8-Takte"


%% Translation of GIT committish: 548076f550a2b7fb09f1260f0e5e2bb028ad396c
texidocfr = "
Aucune règle de ligature automatique n'est disponible pour une mesure à
7/8.  Il faudra donc, en pareil cas, définir vous-même les règles de
regroupement.  Pour, par exemple, ligaturer sur la base de 2/8-3/8-2/8,
il faudra donc définir les terminaisons de 2/8 et 5/8 :

"
  doctitlefr = "Règle de ligature dans une mesure à 7/8"

  lsrtags = "rhythms"
  texidoc = "
There is no default beat structure specified for 7/8 time,
so if automatic beams are required the structure must be specified.  For
example, to group all beams 2-3-2 in 7/8 time, specify the
beat structure to be (2 3 2):
"
  doctitle = "Beam grouping in 7/8 time"
} % begin verbatim


\relative c'' {
  \time 7/8
  % rhythm 2-3-2
  a8 a a a a a a
  \set Score.beatStructure = #'(2 3 2)
  a8 a a a a a a
}
