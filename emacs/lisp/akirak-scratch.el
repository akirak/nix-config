;;; akirak-scratch.el ---  -*- lexical-binding: t -*-

(defvar akirak-scratch-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") #'akirak-scratch-kill-new-and-close)
    (define-key map (kbd "C-c C-k") #'kill-this-buffer)
    (define-key map (kbd "C-c C-w") #'akirak-scratch-duckduckgo)
    map))

(define-minor-mode akirak-scratch-mode
  "Minor mode for language scratch buffers.")

(defun akirak-scratch-kill-new-and-close ()
  (interactive)
  (kill-new (string-trim (buffer-string)))
  (message "Saved the string into the kill ring")
  (kill-buffer))

(defun akirak-scratch-duckduckgo ()
  (interactive)
  (require 'duckduckgo)
  (let* ((text (string-trim (buffer-string)))
         (bang (completing-read (format "DuckDuckGo (with \"%s\"): " text)
                                (duckduckgo-bang--completion)
                                nil nil nil duckduckgo-history)))
    (kill-buffer)
    (duckduckgo (concat bang " " text))
    ;; Also save to the kill ring for re-search
    (kill-new text)))

(cl-defun akirak-scratch-with-input-method (input-method &key language)
  ;; Just in case the default directory no longer exists, set it to a safe one.
  (let ((default-directory user-emacs-directory))
    (with-current-buffer (get-buffer-create
                          (format "*Scratch-Input-Method<%s>*"
                                  input-method))
      (set-input-method input-method)
      (akirak-scratch-mode 1)
      (setq-local header-line-format
                  (list (if language
                            (format "Type %s. " language)
                          "")
                        (substitute-command-keys
                         "\\[akirak-scratch-kill-new-and-close] to save to kill ring, \\[akirak-scratch-duckduckgo] to search, \\[kill-this-buffer] to cancel")))
      (pop-to-buffer (current-buffer)))))

;;;###autoload
(defun akirak-scratch-japanese ()
  (interactive)
  (akirak-scratch-with-input-method 'japanese-riben
                                    :language "Japanese"))

;;;###autoload
(defun akirak-scratch-from-selection ()
  (interactive)
  (let ((text (when (use-region-p)
                (buffer-substring (region-beginning) (region-end)))))
    (with-current-buffer (get-buffer-create "*scratch from selection*")
      (if text
          (insert text)
        (yank))
      (goto-char (point-min))
      (pop-to-buffer (current-buffer)))
    (user-error "No selection")))

(provide 'akirak-scratch)
;;; akirak-scratch.el ends here
