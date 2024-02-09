;;; akirak-compile.el ---  -*- lexical-binding: t -*-

(defcustom akirak-compile-package-file-alist
  '(("dune-project" . dune)
    ("justfile" . just))
  ""
  :type '(alist :key-type (string :tag "File name")
                :value-type (symbol :tag "Symbol to denote the project type")))

;;;###autoload
(defun akirak-compile ()
  (interactive)
  (if-let (workspace (vc-git-root default-directory))
      (pcase (akirak-compile--complete
              (akirak-compile--find-projects (expand-file-name workspace)))
        (`(,command . ,dir)
         (let ((default-directory dir))
           (compile command)))
        ((and command
              (pred stringp))
         (let ((default-directory workspace))
           (compile command t)))))
  (user-error "No VC root"))

(defun akirak-compile--root ()
  (if-let (workspace (vc-git-root default-directory))
      (akirak-compile--find-projects (expand-file-name workspace))
    (user-error "No VC root")))

(defun akirak-compile--parent-dir (dir)
  (thread-last
    dir
    (string-remove-suffix "/")
    (file-name-directory)
    (file-name-as-directory)))

(defun akirak-compile--find-projects (workspace)
  (let* ((start (expand-file-name default-directory))
         result)
    (unless (string-prefix-p workspace start)
      (error "Directory %s is not a prefix of %s" workspace start))
    (cl-labels
        ((search (dir)
           (dolist (file (directory-files dir))
             (when-let (cell (assoc file akirak-compile-package-file-alist))
               (push (cons (cdr cell)
                           dir)
                     result)))
           (unless (equal (file-name-as-directory workspace)
                          (file-name-as-directory dir))
             (search (akirak-compile--parent-dir dir)))))
      (search start))
    result))

(defun akirak-compile--complete (projects)
  "Return (command . dir) or command for the next action for PROJECTS."
  (let (candidates)
    (pcase-dolist (`(,backend . ,dir) projects)
      (let ((command-alist (akirak-compile--gen-commands backend dir))
            (group (format "%s (%s)" backend (abbreviate-file-name dir))))
        (setq candidates (append candidates (mapcar #'car command-alist)))
        (pcase-dolist (`(,command . ,ann) command-alist)
          (add-text-properties 0 1
                               (list 'command-directory dir
                                     'annotation ann
                                     'completion-group group)
                               command)
          (push command candidates))))
    (cl-labels
        ((annotator (candidate)
           (get-text-property 0 'annotation candidate))
         (group (candidate transform)
           (if transform
               candidate
             (get-text-property 0 'completion-group candidate)))
         (completions (string pred action)
           (if (eq action 'metadata)
               (cons 'metadata
                     (list (cons 'category 'my-command)
                           (cons 'group-function #'group)
                           (cons 'annotation-function #'annotator)))
             (complete-with-action action candidates string pred))))
      (let* ((input (completing-read "Compile: " #'completions))
             (dir (get-text-property 0 'command-directory input)))
        (if dir
            (cons input dir)
          input)))))

(defun akirak-compile--gen-commands (backend dir)
  (pcase backend
    (`dune
     '(("dune build")
       ("dune build @doc" . "Build the documentation ")
       ("dune exec")
       ("opam install ")))
    (`just
     (let ((default-directory dir))
       (with-temp-buffer
         (unless (zerop (call-process "just" nil (list t nil) nil
                                      "--dump" "--dump-format" "json"))
           (error "just failed"))
         (goto-char (point-min))
         (thread-last
           (json-parse-buffer :object-type 'alist :array-type 'list
                              :null-object nil)
           (alist-get 'recipes)
           (mapcar (pcase-lambda (`(,name . ,attrs))
                     (cons (format "just %s" name)
                           (alist-get 'doc attrs))))))))))

(provide 'akirak-compile)
;;; akirak-compile.el ends here
