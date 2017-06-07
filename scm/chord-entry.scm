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
         (start-additions #t))
         

    (define (interpret-inversion chord-entries mods)
      "Read /FOO part.  Side effect: INVERSION is set."
      (if (and (> (length mods) 1) (eq? (car mods) 'chord-slash))
          (begin
            (set! inversion (cadr mods))
            (set! mods (cddr mods))))
      (interpret-bass chord-entries mods))

    (define (interpret-bass chord-entries mods)
      "Read /+FOO part.  Side effect: BASS is set."
      (if (and (> (length mods) 1) (eq? (car mods) 'chord-bass))
          (begin
            (set! bass (cadr mods))
            (set! mods (cddr mods))))
      (if (pair? mods)
          (ly:parser-error
           (format #f (_ "Spurious garbage following chord: ~A") mods)))
      chord-entries)

    (define (interpret-removals  chord-entries mods)
      (define (inner-interpret chord-entries mods)
        (if (and (pair? mods) (ly:pitch? (car mods)))
            (inner-interpret (remove-step (+ 1  (ly:pitch-steps (car mods))) chord-entries)
                             (cdr mods))
            (interpret-inversion chord-entries mods)))
      (if (and (pair? mods) (eq? (car mods) 'chord-caret))
          (inner-interpret chord-entries (cdr mods))
          (interpret-inversion chord-entries mods)))

    (define (interpret-additions chord-entries mods)
      "Interpret additions.  TODO: should restrict modifier use?"
      (cond ((null? mods) chord-entries)
            ((ly:pitch? (car mods))
             (case (pitch-step (car mods))
               ((11) (set! explicit-11 #t))
               ((2 4) (set! explicit-2/4 #t))
               ((3) (set! omit-3 #f)))
             (interpret-additions (cons (make-chord-entry (car mods) (pitch-step (car mods)))
                                        (remove-step (pitch-step (car mods)) chord-entries))
                                  (cdr mods)))
             ;; TODO look at these intereperet additions more
            ((procedure? (car mods))
             (interpret-additions ((car mods) chord-entries)
                                  (cdr mods)))
            (else (interpret-removals chord-entries mods))))

    (define (pitch-octavated-strictly-below p root)
      "return P, but octavated, so it is below ROOT"
      (ly:make-pitch (+ (ly:pitch-octave root)
                        (if (> (ly:pitch-notename root)
                               (ly:pitch-notename p))
                            0 -1))
                     (ly:pitch-notename p)
                     (ly:pitch-alteration p)))

    (define (process-inversion complete-chord)
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
            (cons down-inversion rest-of-chord)
            rest-of-chord)))
    ;; BEGINNING OF MAIN FUNCTION
    ;; root is always one octave too low.
    ;; something weird happens when this is removed,
    ;; every other chord is octavated. --hwn... hmmm.
    (set! root (ly:pitch-transpose root (ly:make-pitch 1 0 0)))
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
                ((equal? (ly:make-pitch 0 4 0) (car flat-mods))
                 (set! omit-3 #t)))
          (set! base-chord
                (stack-thirds (car flat-mods) the-canonical-chord))
          (set! flat-mods (cdr flat-mods))))
    ;; apply modifier
    (if (procedure? lead-mod)
        (begin (set! base-chord (lead-mod base-chord))))
    (set! complete-chord
          (if start-additions
              (interpret-additions base-chord flat-mods)
              (interpret-removals base-chord flat-mods)))
    ;; if sus has been given neither 2 or 4, we add 4.
    (if (and (eq? lead-mod sus-modifier)
             (not explicit-2/4))
        (set! complete-chord (cons (make-chord-entry (ly:make-pitch 0 4 0) 4) complete-chord)))
    ;; sort the notes in the chord
    (set! complete-chord (sort complete-chord chord-entry<?))
    ;; If natural 11 + natural 3 is present, but not given explicitly,
    ;; we remove the 11.
    (if (and (not explicit-11)
             (get-step 11 complete-chord)
             (get-step 3 complete-chord)
             (= 0 (ly:pitch-alteration (entry-pitch (get-step 11 complete-chord))))
             (= 0 (ly:pitch-alteration (entry-pitch (get-step 3 complete-chord)))))
        (set! complete-chord (remove-step 11 complete-chord)))
    ;; if omit-3 has been set (and not reset by an explicit 3
    ;; somewhere), we remove the 3
    (if omit-3
        (set! complete-chord (remove-step 3 complete-chord)))
    ;; must do before processing inversion/bass, since they are
    ;; not relative to the root.
    (set! complete-chord (map (lambda (x) (chord-pitch-transpose x root))
                              complete-chord))
    (if inversion
        (set! complete-chord (process-inversion complete-chord)))
    (if bass
        (set! bass (make-chord-entry (pitch-octavated-strictly-below bass root) 'bass)))
    ;; DEBUG STATEMENT
    (if #f
        (begin
          (write-me "\n*******\n" flat-mods)
          (write-me "root: " root)
          (write-me "base chord: " base-chord)
          (write-me "complete chord: " complete-chord)
          (write-me "inversion: " inversion)
          (write-me "bass: " bass)
          (write-me "lead-mod: " lead-mod)))
    (if inversion
        (make-chord-elements (cdr complete-chord) bass duration (car complete-chord)
                             inversion)
        (make-chord-elements complete-chord bass duration #f #f))))


(define (make-chord-elements chord-entries bass duration inversion original-inv-pitch)
  "Make EventChord with notes corresponding to PITCHES, BASS and
DURATION, and INVERSION.  Notes above INVERSION are transposed downward
along with the inversion as long as they end up below at least one
non-inverted note."
  (define (make-note-ev chord-entry . rest)
    (apply make-music 'NoteEvent
           'chord-degree (entry-degree chord-entry)
           'duration duration
           'pitch (entry-pitch chord-entry)
           rest))
  (cond (inversion
         (let* ((octavation (- (ly:pitch-octave inversion)
                               (ly:pitch-octave (car original-inv-pitch))))
                (down (ly:make-pitch octavation 0 0))
                (inv-degree (cdr original-inv-pitch)))
           (define (invert p) (make-chord-entry (ly:pitch-transpose down (entry-pitch p))
                                                (entry-degree p)))
           (define (make-inverted p . rest)
             (apply make-note-ev (invert p) 'octavation octavation rest))
           (receive (uninverted high)
                    (span (lambda (p) (ly:pitch<? (entry-pitch p) (entry-pitch original-inv-pitch)))
                          chord-entries)
                    (receive (invertible rest)
                             (if (null? uninverted)
                                 ;; The following line caters for
                                 ;; inversions "on the root", turning
                                 ;; f/f into <f a' c''> rather than <f a c'>
                                 ;; or <f' a' c''>
                                 (values '() high)
                                 (span (lambda (p)
                                         (ly:pitch<? (entry-pitch (invert p))
                                                     (entry-pitch (car uninverted))))
                                       high))
                             (cons (make-inverted original-inv-pitch 'inversion #t)
                                   (append (if bass (list (make-note-ev bass 'bass #t)) '())
                                           (map make-inverted invertible)
                                           (map make-note-ev uninverted)
                                           (map make-note-ev rest)))))))
        (bass (cons (make-note-ev bass 'bass #t)
                    (map make-note-ev chord-entries)))
        (else
         (begin
           (map make-note-ev chord-entries)))))

;;;;;;;;;;;;;;;;
;; chord modifiers change the pitch list.

(define (aug-modifier chord-entries)
  (set! chord-entries (replace-step (make-chord-entry (ly:make-pitch 0 4 SHARP) 5) chord-entries))
  (replace-step (make-chord-entry (ly:make-pitch 0 2 0) 3) chord-entries))

(define (minor-modifier chord-entries)
  (replace-step (make-chord-entry (ly:make-pitch 0 2 FLAT) 3) chord-entries))

(define (maj7-modifier chord-entries)
  (set! chord-entries (remove-step 7 chord-entries))
  (cons (make-chord-entry (ly:make-pitch 0 6 0) 7) chord-entries))

(define (dim-modifier chord-entries)
  (set! chord-entries (replace-step (make-chord-entry (ly:make-pitch 0 2 FLAT) 3) chord-entries))
  (set! chord-entries (replace-step (make-chord-entry (ly:make-pitch 0 4 FLAT) 5) chord-entries))
  (set! chord-entries (replace-step (make-chord-entry (ly:make-pitch 0 6 DOUBLE-FLAT) 7) chord-entries))
  chord-entries)

(define (sus-modifier chord-entries)
  (remove-step (pitch-step (ly:make-pitch 0 2 0)) chord-entries))

(define-safe-public default-chord-modifier-list
  `((m . ,minor-modifier)
    (min . ,minor-modifier)
    (aug . , aug-modifier)
    (dim . , dim-modifier)
    (maj . , maj7-modifier)
    (sus . , sus-modifier)))

;; Helper function for sorting chord notes
(define (chord-entry<? entry1 entry2)
  (ly:pitch<? (car entry1) (car entry2)))

;; Helper function for transposing chord
(define (chord-pitch-transpose p root)
  (make-chord-entry (ly:pitch-transpose (entry-pitch p) root) (cdr p)))

;; Return pitch of a chord-entry
(define (entry-pitch chord-entry)
  (car chord-entry))

;; Return degree of a chord-entry
(define (entry-degree chord-entry)
  (cdr chord-entry))

;; Make chord-entry out of pitch and degree
(define (make-chord-entry pitch degree)
  (cons pitch degree))

;; canonical 13 chord.
(define the-canonical-chord
  (map (lambda (n)
         (define (nca x)
           (if (= x 7) FLAT 0))
         (if (>= n 8)
             (make-chord-entry (ly:make-pitch 1 (- n 8) (nca n)) n)
             (make-chord-entry (ly:make-pitch 0 (- n 1) (nca n)) n)))
       '(1 3 5 7 9 11 13)))

(define (stack-thirds upper-step base)
  "Stack thirds listed in BASE until we reach UPPER-STEP.  Add
UPPER-STEP separately."
  (cond ((null? base) '())
        ((> (ly:pitch-steps upper-step) (ly:pitch-steps (entry-pitch (car base))))
         (cons (car base) (stack-thirds upper-step (cdr base))))
        ((<= (ly:pitch-steps upper-step) (ly:pitch-steps (entry-pitch (car base))))
         (list (make-chord-entry upper-step  (entry-degree (car base)))))
        (else '())))
