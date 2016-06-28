(defvar uroboro-toplevel-keywords
  '("data" "codata" "function")
  "Keywords of Uroboro that start a top-level entity")

(defvar uroboro-keywords
  (append uroboro-toplevel-keywords '("where"))
  "Keywords of Uroboro, that is, reserved words that look like
  names but are treated specially by the lexer.")

(defvar uroboro-toplevel-keywords-regexp
  (regexp-opt uroboro-toplevel-keywords 'words)
  "Regular expression to match Uroboro keywords that start toplevel entities")

(defvar uroboro-keywords-regexp
  (regexp-opt uroboro-keywords)
  "Regular expression to match Uroboro reserved words.")

(defvar uroboro-interpunctuation
  '(?\. ?\: ?\= ?,)
  "Interpunctuation characters of Uroboro, that is, non-space
  non-matching characters that cannot be part of a name.")

(defvar uroboro-interpunctuation-regexp
  (concat "[" uroboro-interpunctuation "]")
  "Regular expression to match Uroboro interpunctuation characters.")

(defvar uroboro-font-lock-defaults
  `((,uroboro-keywords-regexp . 'font-lock-keyword-face)
    (,uroboro-interpunctuation-regexp . 'font-lock-builtin-face))
  "Font lock configuration for Uroboro.")

(defvar uroboro-command
  "uroboro"
  "Command to use to call the Uroboro interpreter.")

(defun uroboro-setup-fontlock ()
  (setq font-lock-defaults `(uroboro-font-lock-defaults))
  "Install `font-lock-defaults' for Uroboro mode.")

(defun uroboro-setup-syntax-table ()
  "Setup the syntax table for Uroboro mode."
  ; by default, all printable characters are word constituents
  (modify-syntax-entry '(?\x20 . ?\x7F) "w")

  ; whitespace
  (modify-syntax-entry ?\  " ")

  ; interpunctuation
  (dolist (char uroboro-interpunctuation)
    (modify-syntax-entry char "."))

  ; matching characters
  (modify-syntax-entry ?\( "()")
  (modify-syntax-entry ?\) ")(")

  ; comments
  (modify-syntax-entry ?\{  "(}1nb")
  (modify-syntax-entry ?\}  "){4nb")
  (modify-syntax-entry ?-  "_ 123")
  (modify-syntax-entry ?\n ">"))


(defun uroboro-setup-tags ()
  (put 'uroboro-mode 'find-tag-default-function 'uroboro-find-tag-default))

(defun uroboro-setup-indentation ()
  (set (make-local-variable 'indent-line-function) 'uroboro-indent-line))

(defun uroboro-process-file ()
  "Processes the current Uroboro file."
  (interactive)
  (let* ((file-name (buffer-file-name))
         (command (combine-and-quote-strings
                    (list uroboro-command
                          file-name))))
    (compile command)))

(defun uroboro-variable-name-at-point ()
  "Check whether point is inside a Uroboro variable name.
If point is inside a Uroboro variable name, return the
name as a string. Otherwise, return nil.
  This function modifies the match data that `match-beginning',
`match-end' and `match-data' access; save and restore the match
data if you want to preserve them."
  (let ((candidate (thing-at-point 'symbol)))
    (and (stringp candidate)
         (not (string-match (concat "^" uroboro-keywords-regexp "$") candidate))
         candidate)))

(defun uroboro-find-tag-default ()
  "Find default for `find-tag' etc."
  (uroboro-variable-name-at-point))

(defun uroboro-find-toplevel-entity ()
  "Move point to the beginning of the Uroboro toplevel entity point is in."
  (interactive)
  (search-regexp-backwards uroboro-toplevel-keywords-regexp))

(defun uroboro-indent-line ()
  "Indent current line as Uroboro code."
  (interactive)
  (save-excursion
    (beginning-of-line)
    (cond
     ;; line begins a top-level entity -> indent to column 0
     ((looking-at (concat "^\\s-*" uroboro-toplevel-keywords-regexp))
      (indent-line-to 0))

     ;; line begins a line comment -> indent to column 0
     ((looking-at "^\\s-*--")
      (indent-line-to 0))

     ;; line begins a block comment -> indent to column 0
     ((looking-at "^\\s-*{-")
      (indent-line-to 0))

     ;; other line -> indent to column 2
     (t
      (indent-line-to 2)))))

(define-derived-mode uroboro-mode fundamental-mode "uroboro"
  "Major mode for editing Uroboro files."
  (uroboro-setup-fontlock)
  (uroboro-setup-syntax-table)
  (uroboro-setup-tags)
  (uroboro-setup-indentation))

(define-key uroboro-mode-map "\C-c\C-l" 'uroboro-process-file)

(add-to-list 'auto-mode-alist '("\\.uro\\'" . uroboro-mode))

(provide 'uroboro-mode)
