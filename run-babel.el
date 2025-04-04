;; Run without open emacs
;;  emacs --batch -Q -l run-babel.el

(require 'org)
(require 'ob-shell)  ; Explicitly load shell support

(setq org-confirm-babel-evaluate nil)  ; Disable confirmation prompts

(org-babel-do-load-languages
 'org-babel-load-languages
 '((shell . t)))  ; Ensure shell is enabled

(find-file "check-status.org")  ; Replace with your actual file path

;; Execute all code blocks
(org-babel-execute-buffer)

;; Alternative: Execute only specific blocks by name
                                        ; (org-babel-execute-src-block-maybe)

(save-buffer)
