;;;; framework-tex.scm -- structure for TeX output
;;;;
;;;; source file of the GNU LilyPond music typesetter
;;;;
;;;; (c) 2004--2006 Han-Wen Nienhuys <hanwen@cs.uu.nl>

(define-module (scm framework-tex)
  #:export (output-framework-tex	
	    output-classic-framework-tex))

(use-modules (ice-9 regex)
	     (ice-9 string-fun)
	     (ice-9 format)
	     (scm page)
	     (scm paper-system)
	     (guile)
	     (srfi srfi-1)
	     (srfi srfi-13)
	     (srfi srfi-14)
	     (scm kpathsea)
	     (lily))

(define (output-formats)
  (define formats (ly:output-formats))
  (set! formats (completize-formats formats))
  (if (member "ps" formats)
      (set! formats (cons "dvi" formats)))
  (if (member "dvi" formats)
      (set! formats (cons "tex" formats)))

  (uniq-list formats))

(define framework-tex-module (current-module))
(define-public (sanitize-tex-string s)
  (if (ly:get-option 'safe)
      (regexp-substitute/global
       #f "\\\\"
       (regexp-substitute/global #f "([{}])" s 'pre  "\\" 1 'post)
       'pre "$\\backslash$" 'post)
      s))

(define (symbol->tex-key sym)
  (regexp-substitute/global
   #f "_" (sanitize-tex-string (symbol->string sym)) 'pre "X" 'post))

(define (tex-number-def prefix key number)
  (string-append
   "\\def\\" prefix (symbol->tex-key key) "{" number "}%\n"))

(define-public (digits->letters str)
  (regexp-substitute/global
   #f "[-\\._]"
   (regexp-substitute/global
    #f "([0-9])" str
    'pre
    (lambda (match)
      (make-string
       1
       (integer->char
	(+ (char->integer #\A)
	   (- (char->integer #\0))
	   (char->integer (string-ref (match:substring match 1) 0)))
	)))
    'post)
   'pre ""
   'post))

(define-public (tex-font-command-raw name magnification)
  (string-append
   "magfont"
   (digits->letters (format "~a" name))
   "m"
   (string-encode-integer
    (inexact->exact (round (* 1000 magnification))))))

(define-public (tex-font-command font)
  (tex-font-command-raw
   (ly:font-file-name font) (ly:font-magnification font)))

(define (otf-font-load-command paper font)
  (let* ((sub-fonts (ly:font-sub-fonts font)))
    (string-append
     (apply string-append
	    (map
	     (lambda (sub-name)
	       (format #f "\\font\\~a=~a scaled ~a%\n"
		       (tex-font-command-raw
			sub-name (ly:font-magnification font))
		       sub-name
		       (ly:number->string
			(inexact->exact
			 (round (* 1000
				   (ly:font-magnification font)
				   (ly:paper-output-scale paper)))))))
	     sub-fonts)))))

(define (simple-font-load-command paper font)
   (format
    "\\font\\~a=~a scaled ~a%\n"
    (tex-font-command font)
    (ly:font-file-name font)
    (inexact->exact
     (round (* 1000
	       (ly:font-magnification font)
	       (ly:paper-output-scale paper))))))

(define (font-load-command paper font)
  (if (pair? (ly:font-sub-fonts font))
      (otf-font-load-command paper font)
      (simple-font-load-command paper font)))

(define (define-fonts paper)
  (string-append
   ;; UGH. FIXME.
   "\\def\\lilypondpaperunit{mm}%\n"
   (tex-number-def "lilypondpaper" 'output-scale
		   (number->string (exact->inexact
				    (ly:paper-output-scale paper))))
   (tex-string-def "lilypondpaper" 'papersize
		   (eval 'papersizename (ly:output-def-scope paper)))
   ;; paper/layout?
   (tex-string-def "lilypondpaper" 'input-encoding
		   (eval 'input-encoding (ly:output-def-scope paper)))

   (apply string-append
	  (map (lambda (x) (font-load-command paper x))
	       (ly:paper-fonts paper)))))

(define (tex-string-def prefix key str)
  (if (equal? "" (sans-surrounding-whitespace (sanitize-tex-string str)))
      (string-append "\\let\\" prefix (symbol->tex-key key) "\\undefined%\n")
      (string-append "\\def\\" prefix (symbol->tex-key key)
		     "{" (sanitize-tex-string str) "}%\n")))

(define (header paper page-count classic?)
  (let ((scale (ly:output-def-lookup paper 'output-scale))
	(texpaper (string-append
		   (ly:output-def-lookup paper 'papersizename)
		   "paper"))
	(landscape? (eq? #t (ly:output-def-lookup paper 'landscape))))
    (string-append
     "% Generated by LilyPond "
     (lilypond-version) "\n"
     "% at " "time-stamp,FIXME" "\n"
     (if classic?
	 (tex-string-def "lilypond" 'classic "1")
	 "")

     (if (ly:get-option 'safe)
	 "\\nofiles\n"
	 "")

     (tex-string-def
      "lilypondpaper" 'line-width
      (ly:number->string (* scale (ly:output-def-lookup paper 'line-width))))
     "\\def\\lilyponddocumentclassoptions{"
     (sanitize-tex-string texpaper)
     (if landscape? ",landscape" "")
     "}%\n"
     )))

(define (header-end)
  (string-append
   "\\def\\scaletounit{ "
   (number->string lily-unit->bigpoint-factor)
   " mul }%\n"
   "\\ifx\\lilypondstart\\undefined\n"
   "  \\input lilyponddefs\n"
   "\\fi\n"
   "\\lilypondstart\n"
   "\\lilypondspecial\n"
   "\\lilypondpostscript\n"))

(define (dump-page putter page last? with-extents?)
  (ly:outputter-dump-string
   putter
   (format "\\lybox{~a}{~a}{%\n"
	   (if with-extents?
	       (interval-start (ly:stencil-extent page X))
	       0.0)
	   (if with-extents?
	       (- (interval-start (ly:stencil-extent page Y)))
	       0.0)))
  (ly:outputter-dump-stencil putter page)
  (ly:outputter-dump-string
   putter
   (if last?
       "}%\n\\vfill\n"
       "}%\n\\vfill\n\\lilypondpagebreak\n")))

(define-public (output-framework basename book scopes fields)
  (let* ((filename (format "~a.tex" basename))
	 (outputter  (ly:make-paper-outputter (open-file filename "wb") "tex"))
	 (paper (ly:paper-book-paper book))
	 (page-stencils (map page-stencil (ly:paper-book-pages book)))
	 (last-page (car (last-pair pages)))
	 (with-extents
	  (eq? #t (ly:output-def-lookup paper 'dump-extents))))
    (for-each
     (lambda (x)
       (ly:outputter-dump-string outputter x))
     (list
      (header paper (length page-stencils) #f)
      (define-fonts paper)
      (header-end)))
    (ly:outputter-dump-string outputter "\\lilypondnopagebreak\n")
    (for-each
     (lambda (page)
       (dump-page outputter page (eq? last-page page) with-extents))
     page-stencils)
    (ly:outputter-dump-string outputter "\\lilypondend\n")
    (ly:outputter-close outputter)
    (postprocess-output book framework-tex-module filename
			(output-formats))))

(define (dump-line putter line last?)
  (ly:outputter-dump-string
   putter
   (format "\\lybox{~a}{~a}{%\n"
	   (ly:number->string
	    (max 0 (interval-end (paper-system-extent line X))))
	   (ly:number->string
	    (interval-length (paper-system-extent line Y)))))

  (ly:outputter-dump-stencil putter (paper-system-stencil line))
  (ly:outputter-dump-string
   putter
   (if last?
       "}%\n"
       "}\\interscoreline\n")))

(define-public (output-classic-framework
		basename book scopes fields)
  (let* ((filename (format "~a.tex" basename))
	 (outputter  (ly:make-paper-outputter
		      (open-file filename "w") "tex"))
	 (paper (ly:paper-book-paper book))
	 (lines (ly:paper-book-systems book))
	 (last-line (car (last-pair lines))))
    (for-each
     (lambda (x)
       (ly:outputter-dump-string outputter x))
     (list
      ;;FIXME
      (header paper (length lines) #f)
      "\\def\\lilypondclassic{1}%\n"
      (output-scopes scopes fields basename)
      (define-fonts paper)
      (header-end)))

    (for-each
     (lambda (line) (dump-line outputter line (eq? line last-line))) lines)
    (ly:outputter-dump-string outputter "\\lilypondend\n")
    (ly:outputter-close outputter)
    (postprocess-output book framework-tex-module filename
			(output-formats))
    ))

(define-public (output-preview-framework
		basename book scopes fields)
  (let* ((filename (format "~a.tex" basename))
	 (outputter  (ly:make-paper-outputter (open-file filename "wb")
					      "tex"))
	 (paper (ly:paper-book-paper book))
	 (lines (ly:paper-book-systems book))
	 (first-notes-index (list-index
			     (lambda (s) (not (ly:paper-system-title? s)))
			     lines)))

    (for-each
     (lambda (x)
       (ly:outputter-dump-string outputter x))
     (list
      
      ;;FIXME
      (header paper (length lines) #f)
      "\\def\\lilypondclassic{1}%\n"
      (output-scopes scopes fields basename)
      (define-fonts paper)
      (header-end)))

    (for-each
     (lambda (lst)
       (dump-line outputter lst (not (ly:paper-system-title? lst))))
     (take lines (1+ first-notes-index)))
    (ly:outputter-dump-string outputter "\\lilypondend\n")
    (ly:outputter-close outputter)
    (postprocess-output book framework-tex-module filename
			(output-formats))))

(define-public (convert-to-pdf book name)
  (let* ((defs (ly:paper-book-paper book))
	 (paper-width (ly:output-def-lookup defs 'paper-width))
	 (paper-height (ly:output-def-lookup defs 'paper-height))
	 (output-scale (ly:output-def-lookup defs 'output-scale)))
    (postscript->pdf (* paper-width output-scale (/ (ly:bp 1)))
		     (* paper-height output-scale (/ (ly:bp 1)))
		     (string-append (basename name ".tex") ".ps"))))

(define-public (convert-to-png book name)
  (let* ((defs (ly:paper-book-paper book))
	 (resolution (ly:output-def-lookup defs 'pngresolution))
	 (paper-width (ly:output-def-lookup defs 'paper-width))
	 (paper-height (ly:output-def-lookup defs 'paper-height))
	 (output-scale (ly:output-def-lookup defs 'output-scale)))
    (postscript->png
     (if (number? resolution)
	 resolution
	 (ly:get-option 'resolution))

     (* paper-width output-scale (/ (ly:bp 1)))
     (* paper-height output-scale (/ (ly:bp 1)))

     (string-append (basename name ".tex") ".ps"))))

(define-public (convert-to-ps book name)
  (let* ((paper (ly:paper-book-paper book))
	 (preview? (string-contains name ".preview"))
	 (papersizename (ly:output-def-lookup paper 'papersizename))
	 (landscape? (eq? #t (ly:output-def-lookup paper 'landscape)))
	 (base (basename name ".tex"))
	 (ps-name (format "~a.ps"  base ".ps"))
	 (cmd (string-append "dvips"
			     (if preview?
				 " -E"
				 (string-append
				  " -t"
				  ;; careful: papersizename is user-set.
				  (sanitize-command-option papersizename)
				  ""))
			     (if landscape? " -tlandscape" "")
			     (if (ly:kpathsea-find-file "lm.map")
				 " -u+lm.map" "")
			     (if (ly:kpathsea-find-file "ecrm10.pfa")
				 " -u+ec-mftrace.map" "")
			     " -u+lilypond.map -Ppdf" ""
			     " -o" ps-name
			     " " base)))
    (if (access? ps-name W_OK)
	(delete-file ps-name))
    (if (not (ly:get-option 'verbose))
	(begin
	  (ly:message (_ "Converting to `~a'...") (string-append base ".ps"))
	  (ly:progress "\n")))
    (ly:system cmd)))

(define-public (convert-to-dvi book name)
  (let* ((curr-extra-mem
	  (string->number
	   (regexp-substitute/global
	    #f " *%.*\n?"
	    (ly:kpathsea-expand-variable "extra_mem_top")
	    'pre "" 'post)))
	 (base (basename name ".tex"))
	 (cmd (format
	       #f "latex \\\\nonstopmode \\\\input '~a'" name)))

    ;; FIXME: latex 'foo bar' works, but \input 'foe bar' does not?
    (if (string-index name (char-set #\space #\ht #\newline #\cr))
	(ly:error (_"TeX file name must not contain whitespace: `~a'") name))

    (setenv "extra_mem_top" (number->string (max curr-extra-mem 1024000)))
    (let ((dvi-name (string-append base ".dvi")))
      (if (access? dvi-name W_OK)
	  (delete-file dvi-name)))
    (if (not (ly:get-option 'verbose))
	(begin
	  (ly:message (_ "Converting to `~a'...") (string-append base ".dvi"))
	  (ly:progress "\n")))

    ;; FIXME: set in environment?
    (if (ly:get-option 'safe)
	(set! cmd (string-append "openout_any=p " cmd)))

    (ly:system cmd)))

(define-public (convert-to-tex book name)
  #t)

