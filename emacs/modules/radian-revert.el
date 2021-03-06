;; -*- lexical-binding: t -*-

(require 'cl-lib)
(require 'radian-patch)

(use-feature autorevert
  :demand t
  :init

  ;; Make a useful function for putting on hooks in modes where
  ;; `auto-revert-mode' need not print messages.
  (defun radian-revert-silence ()
    "Silence `auto-revert-mode' in the current buffer."
    (setq-local auto-revert-verbose nil))

  :config/el-patch

  ;; Only automatically revert buffers that are visible. This should
  ;; improve performance (because if you have 200 buffers open...).
  ;; This code is originally based on
  ;; https://emacs.stackexchange.com/a/28899/12534.
  (defun auto-revert-buffers ()
    (el-patch-concat
      "Revert buffers as specified by Auto-Revert and Global Auto-Revert Mode.

Should `global-auto-revert-mode' be active all file buffers are checked.

Should `auto-revert-mode' be active in some buffers, those buffers
are checked.

Non-file buffers that have a custom `revert-buffer-function' and
`buffer-stale-function' are reverted either when Auto-Revert
Mode is active in that buffer, or when the variable
`global-auto-revert-non-file-buffers' is non-nil and Global
Auto-Revert Mode is active.

This function stops whenever there is user input.  The buffers not
checked are stored in the variable `auto-revert-remaining-buffers'.

To avoid starvation, the buffers in `auto-revert-remaining-buffers'
are checked first the next time this function is called.

This function is also responsible for removing buffers no longer in
Auto-Revert Mode from `auto-revert-buffer-list', and for canceling
the timer when no buffers need to be checked."
      (el-patch-add
        "\n\nOnly currently displayed buffers are reverted."))

    (setq auto-revert-buffers-counter
          (1+ auto-revert-buffers-counter))

    (save-match-data
      (let ((bufs (el-patch-wrap 2
                    (cl-remove-if-not
                     #'get-buffer-window
                     (if global-auto-revert-mode
                         (buffer-list)
                       auto-revert-buffer-list))))
            remaining new)
        ;; Partition `bufs' into two halves depending on whether or not
        ;; the buffers are in `auto-revert-remaining-buffers'.  The two
        ;; halves are then re-joined with the "remaining" buffers at the
        ;; head of the list.
        (dolist (buf auto-revert-remaining-buffers)
          (if (memq buf bufs)
              (push buf remaining)))
        (dolist (buf bufs)
          (if (not (memq buf remaining))
              (push buf new)))
        (setq bufs (nreverse (nconc new remaining)))
        (while (and bufs
                    (not (and auto-revert-stop-on-user-input
                              (input-pending-p))))
          (let ((buf (car bufs)))
            (with-current-buffer buf
              (if (buffer-live-p buf)
                  (progn
                    ;; Test if someone has turned off Auto-Revert Mode
                    ;; in a non-standard way, for example by changing
                    ;; major mode.
                    (if (and (not auto-revert-mode)
                             (not auto-revert-tail-mode)
                             (memq buf auto-revert-buffer-list))
                        (auto-revert-remove-current-buffer))
                    (when (auto-revert-active-p)
                      ;; Enable file notification.
                      (when (and auto-revert-use-notify
                                 (not auto-revert-notify-watch-descriptor))
                        (auto-revert-notify-add-watch))
                      (auto-revert-handler)))
                ;; Remove dead buffer from `auto-revert-buffer-list'.
                (auto-revert-remove-current-buffer))))
          (setq bufs (cdr bufs)))
        (setq auto-revert-remaining-buffers bufs)
        ;; Check if we should cancel the timer.
        (when (and (not global-auto-revert-mode)
                   (null auto-revert-buffer-list))
          (cancel-timer auto-revert-timer)
          (setq auto-revert-timer nil)))))

  :config

  ;; Turn the delay on auto-reloading from 5 seconds down to 1 second.
  ;; We have to do this before turning on `auto-revert-mode' for the
  ;; change to take effect, unless we do it through
  ;; `customize-set-variable' (which is slow enough to show up in
  ;; startup profiling).
  (setq auto-revert-interval 1)

  ;; Automatically reload files that were changed on disk, if they
  ;; have not been modified in Emacs since the last time they were
  ;; saved.
  (global-auto-revert-mode +1)

  ;; Auto-revert all buffers, not only file-visiting buffers. The
  ;; docstring warns about potential performance problems but this
  ;; should not be an issue since we only revert visible buffers.
  (setq global-auto-revert-non-file-buffers t)

  ;; Since we automatically revert all visible buffers after one second,
  ;; there's no point in asking the user whether or not they want to do
  ;; it when they find a file. This disables that prompt.
  (setq revert-without-query '(".*"))

  ;; Kill the mode line indicator for `auto-revert-mode'.
  (setq auto-revert-mode-text nil))

(provide 'radian-revert)
