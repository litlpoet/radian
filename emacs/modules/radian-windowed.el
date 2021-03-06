;; -*- lexical-binding: t -*-

(defmacro radian-with-windowed-emacs (&rest body)
  "Eval BODY if Emacs is windowed, else return nil."
  (declare (indent defun))
  `(when (display-graphic-p)
     ,@body))

(defmacro radian-with-terminal-emacs (&rest body)
  "Eval BODY if Emacs is not windowed, else return nil."
  (declare (indent defun))
  `(unless (display-graphic-p)
     ,@body))

(provide 'radian-windowed)
