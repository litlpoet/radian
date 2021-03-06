;; -*- lexical-binding: t -*-

(require 'map)

(require 'radian-bind-key)
(require 'radian-check)
(require 'radian-eldoc)
(require 'radian-indent)
(require 'radian-os)
(require 'radian-patch)
(require 'radian-util)

(use-feature lisp-mode
  :config

  (add-hook 'lisp-mode-hook #'aggressive-indent-mode))

;; Package `apples-mode' provides a major mode for AppleScript. For
;; more information on the language, see
;; https://developer.apple.com/library/content/documentation/AppleScript/Conceptual/AppleScriptLangGuide/introduction/ASLR_intro.html.
(use-package apples-mode)

;; Package `go-mode' provides a major mode for Go. For more
;; information on the language, see https://golang.org/.
(use-package go-mode)

;; Package `haskell-mode' provides a major mode for Haskell, including
;; REPL integration. For more information on the language, see
;; https://www.haskell.org/.
(use-package haskell-mode
  :config

  ;; Disable in-buffer underlining of errors and warnings, since we
  ;; already have them from Flycheck.
  (setq haskell-process-show-overlays nil)

  ;; Enable REPL integration when editing Haskell files.
  (add-hook 'haskell-mode-hook #'interactive-haskell-mode))

;; Package `hindent' provides a way to invoke the Haskell code
;; formatter of the same name as a `fill-paragraph' replacement.
(use-package hindent
  :init

  (with-eval-after-load 'haskell-mode

    ;; Don't enable `hindent-mode' in `literate-haskell-mode'. See
    ;; https://github.com/commercialhaskell/hindent/issues/496.

    (defun radian-haskell-maybe-hindent-mode (&optional arg)
      "Enable `hindent-mode' if not in `literate-haskell-mode'.
ARG is passed to `hindent-mode' toggle function."
      (unless (derived-mode-p 'literate-haskell-mode)
        (hindent-mode arg)))

    (add-hook 'haskell-mode-hook #'radian-haskell-maybe-hindent-mode)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; HTML

;; https://www.w3.org/TR/html5/

;; This package provides for editing HTML and HTML-like
;; languages (e.g. templating engines like PHP, ASP, Handlebars,
;; etc.).
(use-package web-mode
  :init

  ;; Enable `web-mode' when editing HTML documents.
  (add-hook 'html-mode-hook #'web-mode)

  :config

  ;; Indent by two spaces by default.
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-code-indent-offset 2)

  ;; Autocomplete </ instantly.
  (setq web-mode-enable-auto-closing t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; JavaScript

(with-eval-after-load 'js
  ;; The standard JavaScript indent width is two spaces, not four.
  (setq js-indent-level 2))

;; Package `js2-mode' provides improved semantic highlighting,
;; indentation, and even simple Flycheck-like warnings for JavaScript
;; code.
(use-package js2-mode
  ;; This is slightly different than what is recommended in the README
  ;; [1]. It seems to make the most sense though. See also [2].
  ;;
  ;; [1]: http://elpa.gnu.org/packages/js2-mode.html
  ;; [2]: https://github.com/PythonNut/emacs-config/blob/41c132ed89d85b96c3cd5267cb86b6bb30ac45f3/modules/config-modes.el#L220-L222
  :mode (("\\.js\\'" . js2-mode)
         ("\\.jsx\\'" . js2-jsx-mode))
  :interpreter ("node" . js2-mode)
  :config

  ;; Change the mode lighters. (They are originally Javascript-IDE and
  ;; JSX-IDE, which are wordy.)

  (defun radian-js2-diminish ()
    "Change the `js2-mode' lighter from Javascript-IDE to JavaScript."
    (setq-local mode-name "JavaScript"))

  (defun radian-js2-jsx-diminish ()
    "Change the `js2-jsx-mode' lighter from JSX-IDE to JSX."
    (setq-local mode-name "JSX"))

  (add-hook 'js2-mode-hook #'radian-js2-diminish)
  (add-hook 'js2-jsx-mode-hook #'radian-js2-jsx-diminish)

  ;; Treat shebang lines (e.g. for node) correctly.
  (setq js2-skip-preprocessor-directives t)

  ;; Don't emit a warning for trailing commas, since there are many
  ;; contexts in which those are valid (anything preprocessed, or
  ;; Node.js).
  (setq js2-strict-trailing-comma-warning nil))

;; This package provides a separate auto-completion backend for
;; JavaScript that is more suitable for general code.
(use-package tern
  :demand t
  :after js2-mode
  :config

  ;; We want Tern to be active whenever we're editing a JavaScript
  ;; file. But not when we're in the Skewer REPL, since there we use
  ;; `ac-js2' instead.
  (add-hook 'js2-mode-hook #'tern-mode)

  :diminish tern-mode)

;; Company backend that uses Tern.
(use-package company-tern
  :demand t
  :after (:all tern company)
  :config

  ;; This allows Company to use suggestions from Tern.
  (add-to-list 'company-backends 'company-tern))

(use-package json-mode
  :init/el-patch

  (defconst json-mode-standard-file-ext '(".json" ".jsonld")
    "List of JSON file extensions.")

  (defsubst json-mode--update-auto-mode (filenames)
    "Update the `json-mode' entry of `auto-mode-alist'.

FILENAMES should be a list of file as string.
Return the new `auto-mode-alist' entry"
    (let* ((new-regexp
            (rx-to-string
             `(seq (eval
                    (cons 'or
                          (append json-mode-standard-file-ext
                                  ',filenames))) eot)))
           (new-entry (cons new-regexp 'json-mode))
           (old-entry (when (boundp 'json-mode--auto-mode-entry)
                        json-mode--auto-mode-entry)))
      (setq auto-mode-alist (delete old-entry auto-mode-alist))
      (add-to-list 'auto-mode-alist new-entry)
      new-entry))

  (defcustom json-mode-auto-mode-list '(".babelrc" ".bowerrc" "composer.lock")
    "List of filename as string to pass for the JSON entry of
`auto-mode-alist'.

Note however that custom `json-mode' entries in `auto-mode-alist'
won’t be affected."
    :group 'json-mode
    :type '(repeat string)
    :set (lambda (symbol value)
           "Update SYMBOL with a new regexp made from VALUE.

This function calls `json-mode--update-auto-mode' to change the
`json-mode--auto-mode-entry' entry in `auto-mode-alist'."
           (set-default symbol value)
           (setq json-mode--auto-mode-entry (json-mode--update-auto-mode value))))

  (defvar json-mode--auto-mode-entry (json-mode--update-auto-mode json-mode-auto-mode-list)
    "Regexp generated from the `json-mode-auto-mode-list'."))

;; Package `markdown-mode' provides syntax highlighting and structural
;; editing commands for Markdown. See
;; https://daringfireball.net/projects/markdown/ for more details on
;; Markdown.
(use-package markdown-mode
  :mode (;; Extension used by Hugo.
         ("\\.mmark\\'" . markdown-mode))
  :config

  (defalias 'radian-advice-markdown-disable-metadata-fontification #'ignore
    "Disable fontification of YAML front-matter in `markdown-mode'.
This is an `:override' advice for
`markdown-match-generic-metadata'. See also
https://github.com/jrblevin/markdown-mode/issues/328.")

  (advice-add #'markdown-match-generic-metadata :override
              #'radian-advice-markdown-disable-metadata-fontification))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Python

;; https://www.python.org/

(use-feature python
  :config

  ;; Slightly less offensive Python docstring style.
  (setq python-fill-docstring-style 'pep-257-nn))

;; Integrated development environment for Python.
(use-package anaconda-mode
  :init

  ;; Enable the functionality of anaconda-mode in Python buffers, as
  ;; suggested in the README [1].
  ;;
  ;; [1]: https://github.com/proofit404/anaconda-mode
  (add-hook 'python-mode-hook #'anaconda-mode)

  :diminish anaconda-mode)

;; Company integration for anaconda-mode.
(use-package company-anaconda
  :init

  (with-eval-after-load 'company
    ;; Enable the functionality of company-anaconda in Python buffers,
    ;; as suggested in the README [1].
    ;;
    ;; [1]: https://github.com/proofit404/company-anaconda

    (defun radian--enable-company-anaconda ()
      (add-to-list 'company-backends #'company-anaconda))

    (add-hook 'python-mode-hook #'radian--enable-company-anaconda)

    ;; Add a space between the completion candidates and the
    ;; chevron-enclosed description, so the completions menu doesn't
    ;; look so crowded.
    (setq company-anaconda-annotation-function
          (lambda (candidate)
            (concat
             " "
             (company-anaconda-annotation
              candidate))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; ReST

;; http://docutils.sourceforge.net/rst.html

(use-feature rst-mode
  :config

  ;; See: https://github.com/flycheck/flycheck/issues/953
  (defun radian-flycheck-maybe-disable-rst ()
    "If inside Sphinx project, disable the `rst' checker from `flycheck'.
This prevents it from signalling spurious errors."
    (with-eval-after-load 'flycheck
      (when (locate-dominating-file default-directory "conf.py")
        (make-local-variable 'flycheck-disabled-checkers)
        (push 'rst flycheck-disabled-checkers)
        (setq-local flycheck-check-syntax-automatically '(save mode-enabled)))))

  (add-hook 'rst-mode-hook #'radian-flycheck-maybe-disable-rst))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Ruby

;; https://www.ruby-lang.org/

(use-feature ruby-mode
  :config

  (add-hook 'ruby-mode-hook #'aggressive-indent-mode))

;; Autocompletion for Ruby.
(use-package robe
  :init

  ;; Enable Robe in Ruby files.
  (add-hook 'ruby-mode-hook #'robe-mode)

  :diminish robe-mode)

;; When you type "do", insert a paired "end".
(use-package ruby-electric
  :init/el-patch

  ;; We already have paired delimiter support from Smartparens.
  ;; However, `ruby-electric' provides its own copy of this
  ;; functionality, in a less optimal way. (In particular, typing a
  ;; closing paren when your cursor is right before a closing paren
  ;; will insert another paren rather than moving through the existing
  ;; one.) Unfortunately, `ruby-electric-delimiters-alist' is defined
  ;; as a constant, so we can't customize it by setting it to nil
  ;; (actually, we can, but byte-compilation inserts the value
  ;; literally at its use sites, so this does not take effect).
  ;; Instead, we override the definition of `ruby-electric-mode-map'
  ;; to make it ignore `ruby-electric-delimiters-alist'. Also note
  ;; that we are actually doing this before `ruby-electric' is loaded.
  ;; This is so that the modification will actually affect the
  ;; definition of `ruby-electric-mode', which gets whatever value
  ;; `ruby-electric-mode-map' happens to have at definition time. (The
  ;; alternative is to also patch `ruby-electric-mode'.)

  (defvar ruby-electric-mode-map
    (let ((map (make-sparse-keymap)))
      (define-key map " " 'ruby-electric-space/return)
      (define-key map [remap delete-backward-char] 'ruby-electric-delete-backward-char)
      (define-key map [remap newline] 'ruby-electric-space/return)
      (define-key map [remap newline-and-indent] 'ruby-electric-space/return)
      (define-key map [remap electric-newline-and-maybe-indent] 'ruby-electric-space/return)
      (define-key map [remap reindent-then-newline-and-indent] 'ruby-electric-space/return)
      (el-patch-remove
        (dolist (x ruby-electric-delimiters-alist)
          (let* ((delim   (car x))
                 (plist   (cdr x))
                 (name    (plist-get plist :name))
                 (func    (plist-get plist :handler))
                 (closing (plist-get plist :closing)))
            (define-key map (char-to-string delim) func)
            (if closing
                (define-key map (char-to-string closing) 'ruby-electric-closing-char)))))
      map)
    (el-patch-concat
      "Keymap used in ruby-electric-mode"
      (el-patch-add ".\n\nThe single-character bindings have been removed.")))

  :init

  ;; Enable `ruby-electric' when editing Ruby code.
  (add-hook 'ruby-mode-hook #'ruby-electric-mode)

  :diminish ruby-electric-mode)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Rust

;; https://www.rust-lang.org/

(use-package rust-mode)

;; Autocompletion for Rust.
(use-package racer
  :init

  (add-hook 'rust-mode-hook #'racer-mode)

  :config

  (add-hook 'racer-mode-hook #'eldoc-mode)
  (with-eval-after-load 'company
    (setq-local company-tooltip-align-annotations t))

  (defun radian--reduce-racer-lag ()
    ;; increased from 0:
    (setq-local company-idle-delay 0.5)
    ;; increased from 0:
    (setq-local eldoc-idle-delay 0.5))

  (add-hook 'racer-mode-hook #'radian--reduce-racer-lag)

  :diminish racer-mode)

;; Package `scheme' provides major modes for Scheme languages. For
;; more information on Scheme, see http://www.schemers.org/.
(use-feature scheme
  :config

  (add-hook 'scheme-mode-hook #'aggressive-indent-mode))

;; Package `geiser' provides REPL integration for several
;; implementations of Scheme.
(use-package geiser)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Shell

;; http://pubs.opengroup.org/onlinepubs/9699919799/utilities/sh.html
;; https://www.gnu.org/software/bash/
;; http://www.zsh.org/

(use-feature sh-script
  :config/el-patch

  ;; Inhibit the "Indentation setup for shell type *sh" message.
  (defun sh-set-shell (shell &optional no-query-flag insert-flag)
    (el-patch-concat
      "Set this buffer's shell to SHELL (a string).
When used interactively, insert the proper starting #!-line,
and make the visited file executable via `executable-set-magic',
perhaps querying depending on the value of `executable-query'.

When this function is called noninteractively, INSERT-FLAG (the third
argument) controls whether to insert a #!-line and think about making
the visited file executable, and NO-QUERY-FLAG (the second argument)
controls whether to query about making the visited file executable.

Calls the value of `sh-set-shell-hook' if set.

Shell script files can cause this function be called automatically
when the file is visited by having a `sh-shell' file-local variable
whose value is the shell name (don't quote it)."
      (el-patch-add
        "\n\nThis function does not print superfluous messages."))
    (interactive (list (completing-read
                        (format "Shell (default %s): "
                                sh-shell-file)
                        ;; This used to use interpreter-mode-alist, but that is
                        ;; no longer appropriate now that uses regexps.
                        ;; Maybe there could be a separate variable that lists
                        ;; the shells, used here and to construct i-mode-alist.
                        ;; But the following is probably good enough:
                        (append (mapcar (lambda (e) (symbol-name (car e)))
                                        sh-ancestor-alist)
                                '("csh" "rc" "sh"))
                        nil nil nil nil sh-shell-file)
                       (eq executable-query 'function)
                       t))
    (if (string-match "\\.exe\\'" shell)
        (setq shell (substring shell 0 (match-beginning 0))))
    (setq sh-shell (sh-canonicalize-shell shell))
    (if insert-flag
        (setq sh-shell-file
              (executable-set-magic shell (sh-feature sh-shell-arg)
                                    no-query-flag insert-flag)))
    (setq mode-line-process (format "[%s]" sh-shell))
    (setq-local sh-shell-variables nil)
    (setq-local sh-shell-variables-initialized nil)
    (setq-local imenu-generic-expression
                (sh-feature sh-imenu-generic-expression))
    (let ((tem (sh-feature sh-mode-syntax-table-input)))
      (when tem
        (setq-local sh-mode-syntax-table
                    (apply 'sh-mode-syntax-table tem))
        (set-syntax-table sh-mode-syntax-table)))
    (dolist (var (sh-feature sh-variables))
      (sh-remember-variable var))
    (if (setq-local sh-indent-supported-here
                    (sh-feature sh-indent-supported))
        (progn
          (el-patch-remove
            (message "Setting up indent for shell type %s" sh-shell))
          (let ((mksym (lambda (name)
                         (intern (format "sh-smie-%s-%s"
                                         sh-indent-supported-here name)))))
            (add-function :around (local 'smie--hanging-eolp-function)
                          (lambda (orig)
                            (if (looking-at "[ \t]*\\\\\n")
                                (goto-char (match-end 0))
                              (funcall orig))))
            (add-hook 'smie-indent-functions #'sh-smie--indent-continuation nil t)
            (smie-setup (symbol-value (funcall mksym "grammar"))
                        (funcall mksym "rules")
                        :forward-token  (funcall mksym "forward-token")
                        :backward-token (funcall mksym "backward-token")))
          (setq-local parse-sexp-lookup-properties t)
          (unless sh-use-smie
            (setq-local sh-kw-alist (sh-feature sh-kw))
            (let ((regexp (sh-feature sh-kws-for-done)))
              (if regexp
                  (setq-local sh-regexp-for-done
                              (sh-mkword-regexpr (regexp-opt regexp t)))))
            (el-patch-remove
              (message "setting up indent stuff"))
            ;; sh-mode has already made indent-line-function local
            ;; but do it in case this is called before that.
            (setq-local indent-line-function 'sh-indent-line))
          (if sh-make-vars-local
              (sh-make-vars-local))
          (el-patch-remove
            (message "Indentation setup for shell type %s" sh-shell)))
      (el-patch-remove
        (message "No indentation for this shell type."))
      (setq-local indent-line-function 'sh-basic-indent-line))
    (when font-lock-mode
      (setq font-lock-set-defaults nil)
      (font-lock-set-defaults)
      (font-lock-flush))
    (setq sh-shell-process nil)
    (run-hooks 'sh-set-shell-hook))

  ;; Inhibit the "Indentation variables are now local" message.
  (defun sh-make-vars-local ()
    (el-patch-concat
      "Make the indentation variables local to this buffer.
Normally they already are local.  This command is provided in case
variable `sh-make-vars-local' has been set to nil.

To revert all these variables to the global values, use
command `sh-reset-indent-vars-to-global-values'."
      (el-patch-add
        "\n\nThis function does not print superfluous messages."))
    (interactive)
    (mapc 'make-local-variable sh-var-list)
    (el-patch-remove
      (message "Indentation variables are now local."))))

;; Package `swift-mode' provides a major mode for Swift code. For more
;; information on Swift, see https://developer.apple.com/swift/.
(use-package swift-mode)

;; Package `auctex' provides major modes for TeX code, including
;; compiler and viewer integration. For more information on TeX, see
;; https://www.tug.org/begin.html.
(straight-use-package '(auctex :host github :repo "raxod502/auctex"
                               :branch "fork/1"
                               :files (:defaults (:exclude "doc/*.texi"))))

(use-feature tex
  :config/el-patch

  ;; Remove annoying messages when opening *.tex files.

  (defun TeX-update-style (&optional force)
    (el-patch-concat
      "Run style specific hooks"
      (el-patch-add
        ", silently,")
      " for the current document.

Only do this if it has not been done before, or if optional argument
FORCE is not nil.")
    (unless (or (and (boundp 'TeX-auto-update)
                     (eq TeX-auto-update 'BibTeX)) ; Not a real TeX buffer
                (and (not force)
                     TeX-style-hook-applied-p))
      (setq TeX-style-hook-applied-p t)
      (el-patch-remove
        (message "Applying style hooks..."))
      (TeX-run-style-hooks (TeX-strip-extension nil nil t))
      ;; Run parent style hooks if it has a single parent that isn't itself.
      (if (or (not (memq TeX-master '(nil t)))
              (and (buffer-file-name)
                   (string-match TeX-one-master
                                 (file-name-nondirectory (buffer-file-name)))))
          (TeX-run-style-hooks (TeX-master-file)))
      (if (and TeX-parse-self
               (null (cdr-safe (assoc (TeX-strip-extension nil nil t)
                                      TeX-style-hook-list))))
          (TeX-auto-apply))
      (run-hooks 'TeX-update-style-hook)
      (el-patch-remove
        (message "Applying style hooks...done"))))

  :config

  ;; The following configuration is recommended in the manual [1].
  ;;
  ;; [1]: https://www.gnu.org/software/auctex/manual/auctex/Quick-Start.html
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)

  (radian-with-operating-system macOS
    ;; Use TeXShop for previewing LaTeX, rather than Preview. This
    ;; means we have to define the command to run TeXShop as a "viewer
    ;; program", and then tell AUCTeX to use the TeXShop viewer when
    ;; opening PDFs.

    (add-to-list 'TeX-view-program-list
                 '("TeXShop" "/usr/bin/open -a TeXShop.app %s.pdf"))
    (map-put TeX-view-program-selection 'output-pdf '("TeXShop")))

  (defun radian-advice-tex-inhibit-style-loading-message
      (TeX-load-style-file file)
    "Inhibit the \"Loading **/auto/*.el (source)...\" messages.
This is an `:around' advice for `TeX-load-style-file'."
    (cl-letf* (((symbol-function #'raw-load) (symbol-function #'load))
               ((symbol-function #'load)
                (lambda (file &optional
                              noerror _nomessage
                              nosuffix must-suffix)
                  (raw-load file noerror 'nomessage nosuffix must-suffix))))
      (funcall TeX-load-style-file file)))

  (advice-add #'TeX-load-style-file :around
              #'radian-advice-tex-inhibit-style-loading-message)

  (with-eval-after-load 'flycheck

    (defun radian-tex-disable-checkers ()
      "Disable chktex and lacheck in TeX buffers."
      (setq-local flycheck-disabled-checkers '(tex-chktex tex-lacheck)))

    (add-hook 'TeX-mode-hook #'radian-tex-disable-checkers)))

(use-feature tex-buf
  :config

  ;; Save buffers automatically when compiling, instead of prompting.
  (setq TeX-save-query nil)

  ;; Hide compilation buffers, as they otherwise get in the way of
  ;; buffer selection.

  (defun radian-advice-tex-hide-compilation-buffers (name)
    "Hide AUCTeX compilation buffers by prepending a space to their names.
This is a `:filter-return' advice for `TeX-process-buffer-name'."
    (concat " " name))

  (advice-add #'TeX-process-buffer-name :filter-return
              #'radian-advice-tex-hide-compilation-buffers))

(use-feature latex
  :config

  ;; Don't be afraid to break inline math between lines.
  (setq LaTeX-fill-break-at-separators nil)

  ;; Make it possible for a document to specify whether or not Biber
  ;; is to be used, via a file-local variable.
  (put 'LaTeX-using-Biber 'safe-local-variable #'booleanp))

(use-feature font-latex
  :config

  ;; Prevent superscripts and subscripts from being displayed in a
  ;; different font size.
  (setq font-latex-fontify-script nil)

  ;; Prevent section headers from being displayed in different font
  ;; sizes.
  (setq font-latex-fontify-sectioning 1)

  ;; If faces were already defined, then we need to explicitly ask for
  ;; them to be updated after changing configuration.
  (when (featurep 'font-latex)
    (font-latex-update-sectioning-faces)))

;; Company integration for AUCTeX.
(use-package company-auctex
  :demand t
  :after tex
  :config

  ;; Enable the functionality of `company-auctex'.
  (company-auctex-init))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TypeScript

;; https://www.typescriptlang.org/

(use-package typescript-mode
  :config

  ;; Capitalize the name of the major mode. For consistency, and OCD.

  (defun radian--rename-typescript-mode-lighter ()
    "Capitalize the TypeScript mode lighter in the current buffer."
    (setq-local mode-name "TypeScript"))

  (add-hook 'typescript-mode-hook #'radian--rename-typescript-mode-lighter)

  ;; The standard TypeScript indent width is two spaces, not four.
  (setq typescript-indent-level 2)

  ;; Disable the tslint syntax checker inside the node_modules
  ;; directory, as it will generally just generate several thousand
  ;; errors, disable itself, and print a warning.

  (with-eval-after-load 'flycheck
    (eval'
     (setf (flycheck-checker-get 'typescript-tslint 'predicate)
           (lambda ()
             (not (string-match-p "/node_modules/" default-directory)))))))

;; TypeScript IDE for Emacs.
(use-package tide
  :init

  ;; Enable Tide (and `tide-mode') when editing TypeScript files.
  (with-eval-after-load 'typescript-mode
    (add-hook 'typescript-mode-hook #'tide-setup))

  :config

  ;; Use tsserver to reformat the buffer on save.

  (defun radian--tide-format-on-save ()
    "Use tsserver to reformat the current buffer on save."
    (add-hook 'before-save-hook #'tide-format-before-save nil 'local))

  (add-hook 'tide-mode-hook #'radian--tide-format-on-save)

  ;; Maintain standard TypeScript indent width.
  (setq tide-format-options '(:indentSize 2 :tabSize 2))

  ;; Enable ElDoc when Tide is active.

  (defun radian--enable-eldoc-in-tide-mode (&rest _args)
    "Enable ElDoc mode in the current buffer.
This is an `:after' advice for `tide-setup'."
    (eldoc-mode 1))

  (advice-add #'tide-setup :after #'radian--enable-eldoc-in-tide-mode)

  :diminish tide-mode)

(provide 'radian-langs)
