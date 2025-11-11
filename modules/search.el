;;; modules/search.el -*- lexical-binding: t; -*-
;;; Commentary:
;;
;;
;; 
;;; Code:

;;; Consult
(use-package consult
  :ensure t
  :bind (("C-s" . consult-line)
	 ("M-y" . consult-yank-pop))

  :init
  ;; Tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  This improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  :config
					; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  ;; (consult-customize
   ;; consult-theme :preview-key '(:debounce 0.2 any)
   ;; consult-ripgrep consult-git-grep consult-grep consult-man
   ;; consult-bookmark consult-recent-file consult-xref
   ;; consult-source-bookmark consult-source-file-register
   ;; consult-source-recent-file consult-source-project-recent-file
   ;; :preview-key "M-."
   ;; :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
  )
