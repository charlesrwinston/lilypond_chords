;;;; This file is part of LilyPond, the GNU music typesetter.
;;;;
;;;; Copyright (C) 2000--2015  Han-Wen Nienhuys <hanwen@xs4all.nl>
;;;;
;;;; LilyPond is free software: you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation, either version 3 of the License, or
;;;; (at your option) any later version.
;;;;
;;;; LilyPond is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License
;;;; along with LilyPond.  If not, see <http://www.gnu.org/licenses/>.



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; jazz-part 2
;;
;; after Klaus Ignatzek,   Die Jazzmethode fuer Klavier 1.
;;
;; The idea is: split chords into
;;
;;  ROOT PREFIXES MAIN-NAME ALTERATIONS SUFFIXES ADDITIONS
;;
;; and put that through a layout routine.
;;
;; the split is a procedural process, with lots of set!.
;;


;; todo: naming is confusing: steps  (0 based) vs. steps (1 based).
(define (pitch-step p)
  "Musicological notation for an interval.  Eg. C to D is 2."
  (+ 1 (ly:pitch-steps p)))

;; Return the chord-entry of step x in chord-entries ps
(define (get-step-chord-entry x ps)
  "Does PS have the X step? Return that step if it does."
  (if (null? ps)
      #f
      (if (= (- x 1) (ly:pitch-steps (entry-pitch (car ps))))
          (car ps)
          (get-step-chord-entry x (cdr ps)))))

;; Return the pitch of step x in pitches ps
(define (get-step x ps)
  "Does PS have the X step? Return that step if it does."
  (if (null? ps)
      #f
      (if (= (- x 1) (ly:pitch-steps (car ps)))
          (car ps)
          (get-step x (cdr ps)))))

;; Replace chord-entry p in chord-entries ps
(define (replace-step p ps)
  "Copy PS, but replace the step of P in PS."
  (if (null? ps)
      '()
      (let* ((t (replace-step p (cdr ps))))
        (if (= (ly:pitch-steps (entry-pitch p)) (ly:pitch-steps (entry-pitch (car ps))))
            (cons p t)
            (cons (car ps) t)))))

;; Remove step x from chord-entries ps
(define (remove-step-chord-entries x ps)
  "Copy PS, but leave out the Xth step."
  (if (null? ps)
      '()
      (let* ((t (remove-step-chord-entries x (cdr ps))))
        (if (= (- x 1) (ly:pitch-steps (entry-pitch (car ps))))
            t
            (cons (car ps) t)))))

;; Remove step x from pitches ps
(define (remove-step x ps)
  "Copy PS, but leave out the Xth step."
  (if (null? ps)
      '()
      (let* ((t (remove-step x (cdr ps))))
        (if (= (- x 1) (ly:pitch-steps (car ps)))
            t
            (cons (car ps) t)))))

;; CHANGE BACK
(define-public (ignatzek-chord-games
                in-pitches bass inversion
                context)

  (define (remove-uptil-step x ps)
    "Copy PS, but leave out everything below the Xth step."
    (if (null? ps)
        '()
        (if (< (ly:pitch-steps (car ps)) (- x 1))
            (remove-uptil-step x (cdr ps))
            ps)))

  (define name-root (ly:context-property context 'chordRootNamer))
  (define name-note
    (let ((nn (ly:context-property context 'chordNoteNamer)))
      (if (eq? nn '())
          ;; replacing the next line with name-root gives guile-error...? -rz

          ;; apparently sequence of defines is equivalent to let, not let* ? -hwn
          (ly:context-property context 'chordRootNamer)
          ;; name-root
          nn)))

  (define (is-natural-alteration? p)
    (= (natural-chord-alteration p) (ly:pitch-alteration p)))

  (define (ignatzek-format-chord-name
           root
           prefix-modifiers
           main-name
           alteration-pitches
           addition-pitches
           suffix-modifiers
           bass-pitch
           lowercase-root?)

    "Format for the given (lists of) pitches.  This is actually more
work than classifying the pitches."

    (define (filter-main-name p)
      "The main name: don't print anything for natural 5 or 3."
      (if
       (or (not (ly:pitch? p))
           (and (is-natural-alteration? p)
                (or (= (pitch-step p) 5)
                    (= (pitch-step p) 3))))
       '()
       (list (name-step p))))

    (define (glue-word-to-step word x)
      (make-line-markup
       (list
        (make-simple-markup word)
        (name-step x))))

    (define (suffix-modifier->markup mod)
      (if (or (= 4 (pitch-step mod))
              (= 2 (pitch-step mod)))
          (glue-word-to-step "sus" mod)
          (glue-word-to-step "huh" mod)))

    (define (prefix-modifier->markup mod)
      (if (and (= 3 (pitch-step mod))
               (= FLAT (ly:pitch-alteration mod)))
          (if lowercase-root?
              empty-markup
              (ly:context-property context 'minorChordModifier))
          (make-simple-markup "huh")))

    (define (filter-alterations alters)
      "Filter out uninteresting (natural) pitches from ALTERS."

      (define (altered? p)
        (not (is-natural-alteration? p)))

      (if
       (null? alters)
       '()
       (let* ((lst (filter altered? alters))
              (lp (last-pair alters)))

         ;; we want the highest also if unaltered
         (if (and (not (altered? (car lp)))
                  (> (pitch-step (car lp)) 5))
             (append lst (last-pair alters))
             lst))))

    (define (name-step pitch)
      (define (step-alteration pitch)
        (- (ly:pitch-alteration pitch)
           (natural-chord-alteration pitch)))

      (let* ((num-markup (make-simple-markup
                          (number->string (pitch-step pitch))))
             (args (list num-markup))
             (major-seven-symbol (ly:context-property context 'majorSevenSymbol))
             (total
                    (if (and (= (ly:pitch-alteration pitch) 0)
                             (= (pitch-step pitch) 7)
                             (markup? major-seven-symbol))
                        (list major-seven-symbol)
                        (cons (accidental->markup (step-alteration pitch)) args))))

        (make-line-markup total)))

    (let* ((sep (ly:context-property context 'chordNameSeparator))
           (slashsep (ly:context-property context 'slashChordSeparator))
           (root-markup (name-root root lowercase-root?))
           (add-pitch-prefix (ly:context-property context 'additionalPitchPrefix))
           (add-markups (map (lambda (x) (glue-word-to-step add-pitch-prefix x))
                             addition-pitches))
           (filtered-alterations (filter-alterations alteration-pitches))
           (alterations (map name-step filtered-alterations))
           (suffixes (map suffix-modifier->markup suffix-modifiers))
           (prefixes (map prefix-modifier->markup prefix-modifiers))
           (main-markups (filter-main-name main-name))
           (to-be-raised-stuff (markup-join
                                (append
                                 main-markups
                                 alterations
                                 suffixes
                                 add-markups) sep))
           (base-stuff (if (ly:pitch? bass-pitch)
                           (list slashsep (name-note bass-pitch #f))
                           '())))

      (set! base-stuff
            (append
             (list root-markup
                   (conditional-kern-before (markup-join prefixes sep)
                                            (and (not (null? prefixes))
                                                 (= (ly:pitch-alteration root) NATURAL))
                                            (ly:context-property context 'chordPrefixSpacer))
                   (make-super-markup to-be-raised-stuff))
             base-stuff))
      (make-line-markup base-stuff)))

  (define (ignatzek-format-exception
           root
           exception-markup
           bass-pitch
           lowercase-root?)

    (make-line-markup
     `(
       ,(name-root root lowercase-root?)
       ,exception-markup
       .
       ,(if (ly:pitch? bass-pitch)
            (list (ly:context-property context 'slashChordSeparator)
                  (name-note bass-pitch #f))
            '()))))

  (let* ((root (car in-pitches))
         (pitches (map (lambda (x) (ly:pitch-diff x root)) (cdr in-pitches)))
         (lowercase-root?
          (and (ly:context-property context 'chordNameLowercaseMinor)
               (let ((third (get-step 3 pitches)))
                 (and third (= (ly:pitch-alteration third) FLAT)))))
         (exceptions (ly:context-property context 'chordNameExceptions))
         (exception (assoc-get pitches exceptions))
         (prefixes '())
         (suffixes '())
         (add-steps '())
         (main-name #f)
         (bass-note
          (if (ly:pitch? inversion)
              inversion
              bass))
         (alterations '()))

    (if exception
        (ignatzek-format-exception root exception bass-note lowercase-root?)

        (begin
          ;; no exception.
          ;; handle sus4 and sus2 suffix: if there is a 3 together with
          ;; sus2 or sus4, then we explicitly say add3.
          (for-each
           (lambda (j)
             (if (get-step j pitches)
                 (begin
                   (if (get-step 3 pitches)
                       (begin
                         (set! add-steps (cons (get-step 3 pitches) add-steps))
                         (set! pitches (remove-step 3 pitches))))
                   (set! suffixes (cons (get-step j pitches) suffixes)))))
           '(2 4))

          ;; do minor-3rd modifier.
          (if (and (get-step 3 pitches)
                   (= (ly:pitch-alteration (get-step 3 pitches)) FLAT))
              (set! prefixes (cons (get-step 3 pitches) prefixes)))

          ;; lazy bum. Should write loop.
          (cond
           ((get-step 7 pitches) (set! main-name (get-step 7 pitches)))
           ((get-step 6 pitches) (set! main-name (get-step 6 pitches)))
           ((get-step 5 pitches) (set! main-name (get-step 5 pitches)))
           ((get-step 4 pitches) (set! main-name (get-step 4 pitches)))
           ((get-step 3 pitches) (set! main-name (get-step 3 pitches))))

          (let* ((3-diff? (lambda (x y)
                            (= (- (pitch-step y) (pitch-step x)) 2)))
                 (split (split-at-predicate
                         3-diff? (remove-uptil-step 5 pitches))))
            (set! alterations (append alterations (car split)))
            (set! add-steps (append add-steps (cdr split)))
            (set! alterations (delq main-name alterations))
            (set! add-steps (delq main-name add-steps))


            ;; chords with natural (5 7 9 11 13) or leading subsequence.
            ;; etc. are named by the top pitch, without any further
            ;; alterations.
            (if (and
                 (ly:pitch? main-name)
                 (= 7 (pitch-step main-name))
                 (is-natural-alteration? main-name)
                 (pair? (remove-uptil-step 7 alterations))
                 (every is-natural-alteration? alterations))
                (begin
                  (set! main-name (last alterations))
                  (set! alterations '())))

            ;; DEBUG
            (newline) (display "HERE RIGHT HERE") (newline)
            (display (ignatzek-format-chord-name
                       root prefixes main-name alterations add-steps suffixes bass-note
                       lowercase-root?))
            (ignatzek-format-chord-name
                       root prefixes main-name alterations add-steps suffixes bass-note
                       lowercase-root?))))))

;; CHANGE BACK
(define-public (ignatzek-chord-names chord-semantics context)
  (define (glue-word-to-step word x)
      (make-line-markup
       (list
        (make-simple-markup word)
        (make-simple-markup (number->string (pitch-step x))))))
  ;; TODO include (and figure out) lower-case root
  (define (make-root-markup root)
    ((ly:context-property context 'chordRootNamer) root #f))
  (define (make-modifier-markup modifier)
    (if modifier
        (cond ((eq? modifier 'min) (make-simple-markup "m"))
              ((eq? modifier 'maj7) (ly:context-property context 'majorSevenSymbol))
              (else (make-simple-markup (symbol->string modifier))))
        empty-markup))
  (define (make-extension-markup extension)
    (if extension
        (make-super-markup (number->string extension))
        empty-markup))
  (define (make-additions-markup additions)
    (define (additions-markup-list additions)
      (map (lambda (x) (glue-word-to-step
                         (ly:context-property context 'additionalPitchPrefix)
                         x))
           additions))
    (if additions
        (make-super-markup (markup-join (additions-markup-list additions)
                                        (ly:context-property context 'chordNameSeparator)))
        empty-markup))
  
  (define (make-removals-markup removals)
    empty-markup)
  (let* ((root (assoc-ref chord-semantics 'root))
         (modifier (assoc-ref chord-semantics 'modifier))
         (extension (assoc-ref chord-semantics 'extension))
         (additions (assoc-ref chord-semantics 'additions))
         (removals (assoc-ref chord-semantics 'removals))
         (root-markup (make-root-markup root))
         (modifier-markup (make-modifier-markup modifier))
         (extension-markup (make-extension-markup extension))
         (additions-markup (make-additions-markup additions))
         (removals-markup (make-removals-markup removals)))
    (make-line-markup
      (list
       (make-root-markup root)
       (make-modifier-markup modifier)
       (make-extension-markup extension)
       (make-additions-markup additions)
       (make-removals-markup removals)))))
