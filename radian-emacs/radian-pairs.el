;;; radian-pairs.el --- Paired delimiter handling

(require 'radian-package)

;; Insert and manipulate paired delimiters.
(use-package smartparens
  :init

  ;; Load the default configuration, including `with-eval-after-load'
  ;; forms for more specific configurations in other modes.
  (require 'smartparens-config)

  :config

  ;; Enable the functionality of Smartparens everywhere.
  (smartparens-global-mode +1)

  ;; Smartparens' Paredit emulation is missing a binding for sexp
  ;; convolution, so we re-add it here.
  (radian-alist-set* "M-?" #'sp-convolute-sexp sp-paredit-bindings)

  ;; Enable some default keybindings for Smartparens.
  (sp-use-paredit-bindings)

  ;; Highlight matching delimiters.
  (show-smartparens-global-mode +1)

  ;; Prevent paired delimiters from ever becoming unpaired, in Lisp
  ;; modes.
  (dolist (mode sp-lisp-modes)
    (let ((mode-hook (intern (format "%S-hook" mode))))
      (add-hook mode-hook #'smartparens-strict-mode)))

  ;; Prevent all highlighting of inserted pairs.
  (setq sp-highlight-pair-overlay nil)
  (setq sp-highlight-wrap-overlay nil)
  (setq sp-highlight-wrap-tag-overlay nil)

  ;; Disable Smartparens in Org-related modes, since the keybindings
  ;; conflict.

  (with-eval-after-load 'org
    (add-to-list 'sp-ignore-modes-list #'org-mode))

  (with-eval-after-load 'org-agenda
    (add-to-list 'sp-ignore-modes-list #'org-agenda-mode)))

(provide 'radian-pairs)

;;; radian-pairs.el ends here
