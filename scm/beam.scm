;;;;
;;;; beam.scm -- Beam scheme stuff
;;;;
;;;; source file of the GNU LilyPond music typesetter
;;;; 
;;;; (c) 2000--2001 Jan Nieuwenhuizen <janneke@gnu.org>
;;;;

;;
;; width in staff space.
;;
(define (default-beam-flag-width-function type)
  (cond
   ((eq? type 1) 1.98) 
   ((eq? type 1) 1.65) ;; FIXME: check what this should be and why
   (else 1.32)))

;; There are several ways to calculate the direction of a beam
;;
;; * majority: number count of up or down notes
;; * mean    : mean centre distance of all notes
;; * median  : mean centre distance weighted per note
;;
;; [Ross] states that the majority of the notes dictates the
;; direction (and not the mean of "center distance")
;;
;; But is that because it really looks better, or because he wants
;; to provide some real simple hands-on rules?
;;     
;; We have our doubts, so we simply provide all sensible alternatives.

(define (dir-compare up down)
  (sign (- up down)))

;; arguments are in the form (up . down)
(define (beam-dir-majority count total)
  (dir-compare (car count) (cdr count)))

(beam-dir-majority '(0 . 0) '(0 . 0))

(define (beam-dir-mean count total)
  (dir-compare (car total) (cdr total)))

(define (beam-dir-median count total)
  (if (and (> (car count) 0)
	   (> (cdr count) 0))
      (dir-compare (/ (car total) (car count)) (/ (cdr total) (cdr count)))
      (dir-compare (car count) (cdr count))))
	    
