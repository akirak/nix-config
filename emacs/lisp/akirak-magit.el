;;; akirak-magit.el --- Extra Magit commands -*- lexical-binding: t -*-

(require 'magit-worktree)
(require 'magit-git)
(require 'akirak-git-clone)
(require 'akirak-project)

(defconst akirak-magit-branch-delim
  ;; One of subdelims in
  ;; https://github.com/NixOS/nix/blob/f7276bc948705f452b2bfcc2a08bc44152f1d5a8/src/libutil/url-parts.hh
  "=")

(defcustom akirak-magit-worktree-category-function #'akirak-git-clone--clock-category
  "Function used to get the current project category.")

(defcustom akirak-magit-worktree-hook
  '(akirak-project-remember-this)
  "Hook to run on a new working tree.

Each function is run without an argument in the new working tree."
  :type 'hook)

;;;###autoload
(defun akirak-magit-worktree-default ()
  "Check out a new branch in a worktree at the default location."
  (interactive)
  (pcase-let*
      ((`(,remote ,default) (magit--get-default-branch))
       (`(,branch ,start-point) (magit-branch-read-args "Create and checkout branch"
                                                        (format "%s/%s"
                                                                remote
                                                                (or default "master"))))
       (origin-name (akirak-magit--repo-name (car (akirak-magit--remote-url remote))))
       (name (concat origin-name akirak-magit-branch-delim branch))
       (category (akirak-git-clone--clock-category))
       (parent (or (when category
                     (akirak-git-clone-default-parent category))
                   (akirak-git-clone-read-parent (format "Select a parent directory of \"%s\": "
                                                         name)
                                                 category))))
    (magit-worktree-branch (concat (file-name-as-directory (or parent "~/work2/"))
                                   name)
                           branch start-point)
    (run-hooks 'akirak-magit-worktree-hook)))

(defun akirak-magit--remote-url (remote)
  (magit-config-get-from-cached-list (format "remote.%s.url" remote)))

(defun akirak-magit--repo-name (git-url)
  (if (string-match (rx (any ":/") (group (+? (not (any "/")))) (?  ".git") eol)
                    git-url)
      (match-string 1 git-url)
    (error "Failed to parse the repository name from %s" git-url)))

(provide 'akirak-magit)
;;; akirak-magit.el ends here
