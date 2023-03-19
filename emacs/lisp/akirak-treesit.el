;;; akirak-treesit.el --- Treesit-based navigation mode -*- lexical-binding: t -*-

(require 'treesit)

(defvar akirak-treesit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap forward-word] #'akirak-treesit-forward-word)
    (define-key map [remap backward-word] #'akirak-treesit-backward-word)
    (define-key map [remap kill-word] #'akirak-treesit-kill-word)
    (define-key map [remap down-list] #'akirak-treesit-down-list)
    (define-key map [remap backward-up-list] #'akirak-treesit-backward-up-list)
    map))

;;;###autoload
(define-minor-mode akirak-treesit-mode
  "Navigation mode based on treesit.el.")

(defun akirak-treesit-forward-word (n)
  (interactive "P")
  (let ((node (treesit-node-at (point))))
    (cond
     ((or (not n)
          (and (numberp n)
               (> n 0)))
      (if (> (treesit-node-end node)
             (point))
          (progn
            (goto-char (treesit-node-end node))
            (when (looking-at (rx (+ blank)))
              (goto-char (match-end 0))))
        (while (= (treesit-node-end node) (point))
          (setq node (treesit-node-parent node)))
        (let* ((siblings (treesit-node-children node))
               (sibling (seq-find `(lambda (x)
                                     (> (treesit-node-start x) ,(point)))
                                  siblings)))
          (goto-char (treesit-node-start sibling))))
      (when (and (numberp n)
                 (> n 1))
        (akirak-treesit-forward-word (1- n))))
     ((= n 0))
     ((< n 0)
      (akirak-treesit-backward-word (- n))))))

(defun akirak-treesit-backward-word (n)
  (interactive "P")
  (let ((node (treesit-node-at (point))))
    (if (< (treesit-node-start node) (point))
        (progn
          (goto-char (treesit-node-start node))
          (when (and n (> n 1))
            (akirak-treesit-backward-word (1- n))))
      (if-let* ((parent (treesit-node-parent node))
                (children (seq-filter `(lambda (node)
                                         (< (treesit-node-start node)
                                            ,(point)))
                                      (treesit-node-children parent))))
          (progn
            (goto-char (treesit-node-start (car (last children))))
            (when (and n (> n 1))
              (akirak-treesit-backward-word (1- n))))
        (backward-word n)))))

(defun akirak-treesit-kill-word (n)
  (interactive "P")
  (let ((node (treesit-node-at (point))))
    (cond
     ((and (numberp n)
           (= n 0)))
     ((or (not n)
          (and (numberp n)
               (> n 0)))
      (delete-region (point) (treesit-node-end node))
      (when (looking-at (rx (+ blank)))
        (delete-region (point) (match-end 0)))
      (when (and (numberp n)
                 (> n 0))
        (akirak-treesit-kill-word (1- n)))))))

(defun akirak-treesit-down-list ()
  (interactive)
  (let ((start (point)))
    (cl-labels
        ((pred (x)
           (when-let (child (cadr (treesit-node-children x)))
             (when (> (treesit-node-start child)
                      start)
               child)))
         (go (node)
           (let ((nodes (treesit-node-children (treesit-node-parent node))))
             (if-let (child (seq-some #'pred nodes))
                 (goto-char (treesit-node-start child))
               (go (treesit-node-parent node))))))
      (go (treesit-node-at (point))))))

(defun akirak-treesit-backward-up-list ()
  (interactive)
  (let ((node (treesit-node-at (point)))
        parent)
    (while (and (setq parent (treesit-node-parent node))
                (= (point) (treesit-node-start parent)))
      (setq node parent))
    (goto-char (treesit-node-start parent))))

(defvar akirak-treesit-expand-region-node nil)

;;;###autoload
(defun akirak-treesit-expand-region ()
  (interactive)
  (unless (and akirak-treesit-expand-region-node
               (use-region-p)
               (eq (treesit-node-start akirak-treesit-expand-region-node)
                   (region-beginning))
               (eq (treesit-node-end akirak-treesit-expand-region-node)
                   (region-end)))
    (setq akirak-treesit-expand-region-node nil))
  (let* ((node (if akirak-treesit-expand-region-node
                   (treesit-node-parent akirak-treesit-expand-region-node)
                 (treesit-node-at (point))))
         (start (treesit-node-start node)))
    (when (use-region-p)
      (deactivate-mark))
    (goto-char start)
    (activate-mark)
    (goto-char (treesit-node-end node))
    (push-mark)
    (goto-char start)
    (setq akirak-treesit-expand-region-node node)))

(provide 'akirak-treesit)
;;; akirak-treesit.el ends here
