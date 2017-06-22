;;;; This file is part of LilyPond, the GNU music typesetter.
;;;;
;;;; Copyright (C) 2004--2015 Han-Wen Nienhuys <hanwen@xs4all.nl>
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

;; for define-safe-public when byte-compiling using Guile V2
(use-modules (scm safe-utility-defs) (ice-9 receive))

(define-session-public chordmodifiers '())

(define-public (construct-chord-elements root duration modifications)
  "Build a chord on root using modifiers in @var{modifications}.
@code{NoteEvents} have duration @var{duration}.

Notes: Natural 11 is left from chord if not explicitly specified.

Entry point for the parser."
  (let* ((flat-mods (flatten-list modifications))
         (base-chord (stack-thirds (ly:make-pitch 0 4 0) the-canonical-chord))
         (complete-chord '())
         (bass #f)
         (inversion #f)
         (lead-mod #f)
         (explicit-11 #f)
         (explicit-2/4 #f)
         (omit-3 #f)
         (start-additions #t)
         (chord-semantics `((modifier . #f) (root . ,(ly:make-pitch 0 0 0))
                            (extension . #f) (additions . ()) (removals . ())
                            (bass . #f))))

    (define (interpret-inversion chord-entries mods chord-semantics)
      "Read /FOO part.  Side effect: INVERSION is set."
      (if (and (> (length mods) 1) (eq? (car mods) 'chord-slash))
          (begin
            (set! inversion (cadr mods))
            (update-chord-semantics chord-semantics 'bass inversion)
            (set! mods (cddr mods))))
      (interpret-bass chord-entries mods chord-semantics))

    (define (interpret-bass chord-entries mods chord-semantics)
      "Read /+FOO part.  Side effect: BASS is set."
      (if (and (> (length mods) 1) (eq? (car mods) 'chord-bass))
          (begin
            (set! bass (cadr mods))
            (update-chord-semantics chord-semantics 'bass bass)
            (set! mods (cddr mods))))
      (if (pair? mods)
          (ly:parser-error
           (format #f (_ "Spurious garbage following chord: ~A") mods)))
      chord-entries)

    (define (interpret-removals chord-entries mods chord-semantics)
      (define (inner-interpret chord-entries mods chord-semantics)
        (if (and (pair? mods) (ly:pitch? (car mods)))
            (begin (update-chord-semantics chord-semantics
                                           'removals
                                           (cons (car mods)
                                                 (get-chord-semantics chord-semantics 'removals)))
                   (inner-interpret (remove-step-chord-entries (+ 1  (ly:pitch-steps (car mods))) chord-entries)
                                    (cdr mods)
                                    chord-semantics))
            (interpret-inversion chord-entries mods chord-semantics)))
      (if (and (pair? mods) (eq? (car mods) 'chord-caret))
          (inner-interpret chord-entries (cdr mods) chord-semantics)
          (interpret-inversion chord-entries mods chord-semantics)))

    (define (interpret-additions chord-entries mods chord-semantics)
      "Interpret additions.  TODO: should restrict modifier use?"
      (cond ((null? mods) chord-entries)
            ((ly:pitch? (car mods))
             (case (pitch-step (car mods))
               ((11) (set! explicit-11 #t))
               ((2 4) (set! explicit-2/4 #t))
               ((3) (set! omit-3 #f)))
             (update-chord-semantics chord-semantics
                                     'additions
                                     (cons (car mods)
                                           (get-chord-semantics chord-semantics 'additions)))
             (interpret-additions (cons (make-chord-entry-from-pitch (car mods))
                                        (remove-step-chord-entries (pitch-step (car mods)) chord-entries))
                                  (cdr mods)
                                  chord-semantics))
            ((procedure? (car mods))
             (interpret-additions ((car mods) chord-entries)
                                  (cdr mods)
                                  (chord-semantics)))
            (else (interpret-removals chord-entries mods chord-semantics))))

    (define (pitch-octavated-strictly-below p root)
      "return P, but octavated, so it is below ROOT"
      (ly:make-pitch (+ (ly:pitch-octave root)
                        (if (> (ly:pitch-notename root)
                               (ly:pitch-notename p))
                            0 -1))
                     (ly:pitch-notename p)
                     (ly:pitch-alteration p)))

    (define (process-inversion complete-chord chord-semantics)
      "Take out inversion from COMPLETE-CHORD, and put it at the bottom.
Return (INVERSION . REST-OF-CHORD).

Side effect: put original pitch in INVERSION.
If INVERSION is not in COMPLETE-CHORD, it will be set as a BASS, overriding
the bass specified.

"
      (let* ((root-entry (car complete-chord))
             (inv? (lambda (y)
                     (and (= (ly:pitch-notename (entry-pitch y))
                             (ly:pitch-notename inversion))
                          (= (ly:pitch-alteration (entry-pitch y))
                             (ly:pitch-alteration inversion)))))
             (rest-of-chord (remove inv? complete-chord))
             (inversion-candidates (filter inv? complete-chord))
             (down-inversion (pitch-octavated-strictly-below inversion (entry-pitch root-entry))))
        (if (pair? inversion-candidates)
            (set! inversion (car inversion-candidates))
            (begin
              (set! bass inversion)
              (set! inversion #f)))
        (if inversion
            (begin
              (update-chord-semantics chord-semantics 'bass down-inversion)
              (cons down-inversion rest-of-chord))
            rest-of-chord)))
    ;; BEGINNING OF MAIN PROCEDURE
    ;; root is always one octave too low.
    ;; something weird happens when this is removed,
    ;; every other chord is octavated. --hwn... hmmm.
    (set! root (ly:pitch-transpose root (ly:make-pitch 1 0 0)))
    (update-chord-semantics chord-semantics 'root root)
    ;; skip the leading : , we need some of the stuff following it.
    (if (pair? flat-mods)
        (if (eq? (car flat-mods) 'chord-colon)
            (set! flat-mods (cdr flat-mods))
            (set! start-additions #f)))
    ;; remember modifier
    (if (and (pair? flat-mods) (procedure? (car flat-mods)))
        (begin
          (set! lead-mod (car flat-mods))
          (set! flat-mods (cdr flat-mods))))
    ;; extract first number if present, and build pitch list.
    (if (and (pair? flat-mods)
             (ly:pitch?  (car flat-mods))
             (not (eq? lead-mod sus-modifier)))
        (begin
          (cond ((= (pitch-step (car flat-mods)) 11)
                 (set! explicit-11 #t))
                ;; TODO: this omits 3 in power chord. Change to only do so if lead-mod is null.
                ((equal? (ly:make-pitch 0 4 0) (car flat-mods))
                 (set! omit-3 #t)))
          (set! base-chord
                (stack-thirds (car flat-mods) the-canonical-chord))
          (update-chord-semantics chord-semantics 'extension (pitch-step (car flat-mods)))
          (set! flat-mods (cdr flat-mods))))
    ;; apply modifier
    (if (procedure? lead-mod)
        (begin
          (set! base-chord (lead-mod base-chord))
          (update-chord-semantics chord-semantics 'modifier (mod-symbol lead-mod))))
    ;; interperet additions and removals
    (set! complete-chord
          (if start-additions
              (interpret-additions base-chord flat-mods chord-semantics)
              (interpret-removals base-chord flat-mods chord-semantics)))
    ;; if sus has been given neither 2 or 4, we add 4.
    ;; TODO: how to deal with sus semantics with 2 and 4
    ;; TODO: is this right?? It looks like it adds the fifth.
    (if (and (eq? lead-mod sus-modifier)
             (not explicit-2/4))
        (set! complete-chord (cons (make-chord-entry (ly:make-pitch 0 4 0)
                                                     (make-chord-step 4 'perfect))
                                   complete-chord)))
    ;; sort the notes in the chord
    (set! complete-chord (sort complete-chord chord-entry<?))
    ;; If natural 11 + natural 3 is present, but not given explicitly,
    ;; we remove the 11.
    ;; TODO: make sure 11 is removed in this case.
    (if (and (not explicit-11)
             (get-step-chord-entry 11 complete-chord)
             (get-step-chord-entry 3 complete-chord)
             (= 0 (ly:pitch-alteration (entry-pitch (get-step-chord-entry 11 complete-chord))))
             (= 0 (ly:pitch-alteration (entry-pitch (get-step-chord-entry 3 complete-chord)))))
        (set! complete-chord (remove-step-chord-entries 11 complete-chord)))
    ;; if omit-3 has been set (and not reset by an explicit 3
    ;; somewhere), we remove the 3
    (if omit-3
        (begin
          (set! complete-chord (remove-step-chord-entries 3 complete-chord))
          (update-chord-semantics chord-semantics
                                  'removals
                                  (cons 3 (get-chord-semantics chord-semantics 'removals)))))
    ;; must do before processing inversion/bass, since they are
    ;; not relative to the root.
    (set! complete-chord (map (lambda (x) (chord-pitch-transpose x root))
                              complete-chord))
    (if inversion    
        (set! complete-chord (process-inversion complete-chord chord-semantics)))
    (if bass
        (begin
          (set! bass (make-chord-entry (pitch-octavated-strictly-below bass root) 'bass))
          (update-chord-semantics chord-semantics 'bass (entry-pitch bass))))
    (sort-chord-semantics chord-semantics)
    ;; DEBUG STATEMENT
    (if #f
        (begin
          (write-me "\n*******\n" flat-mods)
          (write-me "root: " root)
          (write-me "base chord: " base-chord)
          (write-me "complete chord: " complete-chord)
          (write-me "inversion: " inversion)
          (write-me "bass: " bass)))
    (if inversion
        (make-chord-elements (cdr complete-chord) bass duration (car complete-chord)
                             inversion chord-semantics)
        (make-chord-elements complete-chord bass duration #f #f chord-semantics))))


(define (make-chord-elements chord-entries bass duration inversion original-inv-pitch chord-semantics)
  "Make EventChord with notes corresponding to PITCHES, BASS and
DURATION, and INVERSION.  Notes above INVERSION are transposed downward
along with the inversion as long as they end up below at least one
non-inverted note."
  (define (make-note-ev chord-entry . rest)
    (apply make-music 'NoteEvent
           'chord-step (entry-chord-step chord-entry)
           'duration duration
           'pitch (entry-pitch chord-entry)
           rest))
  (define (make-chord-semantics-ev chord-semantics)
    (make-music 'ChordSemanticsEvent
                'chord-semantics chord-semantics))
  (define (make-elements note-events chord-semantics)
    (cons (make-chord-semantics-ev chord-semantics) note-events))
  (cond (inversion
         (let* ((octavation (- (ly:pitch-octave inversion)
                               (ly:pitch-octave (entry-pitch original-inv-pitch))))
                (down (ly:make-pitch octavation 0 0))
                (inv-semantics (entry-chord-step original-inv-pitch)))
           (define (invert-chord-entry p)
             (make-chord-entry (ly:pitch-transpose down (entry-pitch p))
                               (entry-chord-step p)))
           (define (make-inverted p . rest)
             (apply make-note-ev (invert-chord-entry p) 'octavation octavation rest))
           (receive (uninverted high)
                    (span (lambda (p) (ly:pitch<? (entry-pitch p)
                                                  (entry-pitch original-inv-pitch)))
                          chord-entries)
                    (receive (invertible rest)
                             (if (null? uninverted)
                                 ;; The following line caters for
                                 ;; inversions "on the root", turning
                                 ;; f/f into <f a' c''> rather than <f a c'>
                                 ;; or <f' a' c''>
                                 (values '() high)
                                 (span (lambda (p)
                                         (ly:pitch<? (entry-pitch (invert-chord-entry p))
                                                     (entry-pitch (car uninverted))))
                                       high))
                             (make-elements (cons (make-inverted original-inv-pitch 'inversion #t)
                                                  (append (if bass (list (make-note-ev bass 'bass #t)) '())
                                                          (map make-inverted invertible)
                                                          (map make-note-ev uninverted)
                                                          (map make-note-ev rest)))
                                            chord-semantics)))))
        (bass (make-elements (cons (make-note-ev bass 'bass #t)
                                   (map make-note-ev chord-entries))
                             chord-semantics))
        (else (make-elements (map make-note-ev chord-entries) chord-semantics))))

;;;;;;;;;;;;;;;;

;; get symbol from modifier
(define (mod-symbol lead-mod)
  (cond ((eq? lead-mod aug-modifier) 'aug)
        ((eq? lead-mod minor-modifier) 'min)
        ((eq? lead-mod maj7-modifier) 'maj7)
        ((eq? lead-mod dim-modifier) 'dim)
        ((eq? lead-mod sus-modifier) 'sus)))

;; update chord-semantics list
(define (update-chord-semantics semantics-list key value)
  (assoc-set! semantics-list key value))

;; get value from key in chord-semantics
(define (get-chord-semantics semantics-list key)
  (assoc-ref semantics-list key))

;; sorts additions and removals entries of chord-semantics
(define (sort-chord-semantics chord-semantics)
  (update-chord-semantics chord-semantics
                          'additions
                          (sort (get-chord-semantics chord-semantics 'additions) ly:pitch<?))
  (update-chord-semantics chord-semantics
                          'removals
                          (sort (get-chord-semantics chord-semantics 'removals) ly:pitch<?)))

;; get value from key in chord-semantics
(define (get-chord-semantics semantics-list key)
  (assoc-ref semantics-list key))

;; chord modifiers change the pitch list.
(define (aug-modifier chord-entries)
  (set! chord-entries (replace-step (make-chord-entry (ly:make-pitch 0 4 SHARP)
                                                      (make-chord-step 5 'aug))
                                    chord-entries))
  (replace-step (make-chord-entry (ly:make-pitch 0 2 0)
                                  (make-chord-step 3 'maj))
                chord-entries))

(define (minor-modifier chord-entries)
  (replace-step (make-chord-entry (ly:make-pitch 0 2 FLAT)
                                  (make-chord-step 3 'min))
                chord-entries))

(define (maj7-modifier chord-entries)
  (set! chord-entries (remove-step-chord-entries 7 chord-entries))
  (cons (make-chord-entry (ly:make-pitch 0 6 0)
                          (make-chord-step 7 'maj))
        chord-entries))

(define (dim-modifier chord-entries)
  (set! chord-entries (replace-step (make-chord-entry (ly:make-pitch 0 2 FLAT)
                                                      (make-chord-step 3 'min))
                                    chord-entries))
  (set! chord-entries (replace-step (make-chord-entry (ly:make-pitch 0 4 FLAT)
                                                      (make-chord-step 5 'dim))
                                    chord-entries))
  (set! chord-entries (replace-step (make-chord-entry (ly:make-pitch 0 6 DOUBLE-FLAT)
                                                      (make-chord-step 7 'dim))
                                    chord-entries))
  chord-entries)

(define (sus-modifier chord-entries)
  (remove-step-chord-entries (pitch-step (ly:make-pitch 0 2 0)) chord-entries))

(define-safe-public default-chord-modifier-list
  `((m . ,minor-modifier)
    (min . ,minor-modifier)
    (aug . , aug-modifier)
    (dim . , dim-modifier)
    (maj . , maj7-modifier)
    (sus . , sus-modifier)))

;; Helper function for sorting chord entries
(define (chord-entry<? entry1 entry2)
  (ly:pitch<? (entry-pitch entry1) (entry-pitch entry2)))

;; Helper function for transposing a chord
(define (chord-pitch-transpose p root)
  (make-chord-entry (ly:pitch-transpose (entry-pitch p) root) (entry-chord-step p)))

;; Return pitch of a chord-entry
(define (entry-pitch chord-entry)
  (car chord-entry))

;; Return chord-step of chord-entry
(define (entry-chord-step chord-entry)
  (cdr chord-entry))

;; Make chord-entry out of pitch and chord-step
(define (make-chord-entry pitch chord-step)
  (cons pitch chord-step))

;; Make chord-entry from just pitch
(define (make-chord-entry-from-pitch pitch)
  (let* ((step-number (pitch-step pitch))
         (alteration (ly:pitch-alteration pitch))
         (quality 'maj))
    (cond ((or (= step-number 2) (= step-number 9))
           (cond ((= alteration SHARP) (set! quality 'aug))
                 ((= alteration FLAT) (set! quality 'min))
                 ((= alteration DOUBLE-FLAT) (set! quality 'dim))))
          ((or (= step-number 3) (= step-number 10))
           (cond ((= alteration SHARP) (set! quality 'aug))
                 ((= alteration FLAT) (set! quality 'min))
                 ((= alteration DOUBLE-FLAT) (set! quality 'dim))))
          ((or (= step-number 4) (= step-number 11)) ;; TODO: will 11 have the same qualities as 4?
           (cond ((= alteration 0) (set! quality 'perfect))
                 ((= alteration SHARP) (set! quality 'aug))
                 ((= alteration FLAT) (set! quality 'dim))))
          ((or (= step-number 5) (= step-number 12))
           (cond ((= alteration 0) (set! quality 'perfect))
                 ((= alteration SHARP) (set! quality 'aug))
                 ((= alteration FLAT) (set! quality 'dim))))
          ((or (= step-number 6) (= step-number 13))
           (cond ((= alteration SHARP) (set! quality 'aug))
                 ((= alteration FLAT) (set! quality 'min))
                 ((= alteration DOUBLE-FLAT) (set! quality 'dim))))
          ((or (= step-number 1) (= step-number 8)) ;; TODO: define this better...
           (cond ((= alteration 0) (set! quality 'perfect))
                 ((= alteration SHARP) (set! quality 'aug))
                 ((= alteration FLAT) (set! quality 'dim)))))
    (make-chord-entry pitch (make-chord-step step-number quality))))

;; Make single chord-step
(define (make-chord-step number quality)
  (list (cons 'step-number number) (cons 'step-quality quality)))

;; make chord-step list used in canonical 13
(define (make-chord-step-list chord-step-list step-number)
  (define quality 'major)
  (if (= step-number 1) (set! quality 'perfect))
  (if (= step-number 5) (set! quality 'perfect))
  (if (= step-number 7) (set! quality 'min))
  (if (= step-number 15) (reverse chord-step-list)
      (make-chord-step-list
          (cons (list (cons 'step-number step-number) (cons 'step-quality quality)) chord-step-list)
          (+ step-number 2))))

;; canonical 13 chord.
(define the-canonical-chord
  (map (lambda (chord-step)
         (define (nca x)
           (if (= x 7) FLAT 0))
         (define n (assoc-ref chord-step 'step-number))
         (if (>= n 8)
             (make-chord-entry (ly:make-pitch 1 (- n 8) (nca n)) chord-step)
             (make-chord-entry (ly:make-pitch 0 (- n 1) (nca n)) chord-step)))
       (make-chord-step-list '() 1)
         ))
 
(define (stack-thirds upper-step base)
  "Stack thirds listed in BASE until we reach UPPER-STEP.  Add
UPPER-STEP separately."
  (cond ((null? base) '())
        ((> (ly:pitch-steps upper-step) (ly:pitch-steps (entry-pitch (car base))))
         (cons (car base) (stack-thirds upper-step (cdr base))))
        ((<= (ly:pitch-steps upper-step) (ly:pitch-steps (entry-pitch (car base))))
         (list (make-chord-entry upper-step  (entry-chord-step (car base)))))
        (else '())))
