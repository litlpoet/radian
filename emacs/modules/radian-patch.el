;; -*- lexical-binding: t -*-

;; Occasionally you need to customize a small part of a large function
;; defined by another package. This library provides an elegant,
;; clear, and robust way of doing so. See the README [1].
;;
;; [1]: https://github.com/raxod502/el-patch
(use-package el-patch
  :straight (:host github
                   :repo "raxod502/el-patch"
                   :branch "develop")
  :demand t
  :config

  ;; When patching variable definitions, override the original values.
  (setq el-patch-use-aggressive-defvar t))

(provide 'radian-patch)
