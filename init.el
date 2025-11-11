;;; init.el -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; The heart of my config!
;;
;;; Code:

(setq disabled-command-function nil)

;;; Line Numbers

(add-hook 'prog-mode-hook 'display-line-numbers-mode)

;;; Saving/Backups/Lockfils/Custom-File

(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

(setq backup-by-copying t)
(setq backup-directory-alist
      `(("." . ,(expand-file-name "backup" user-emacs-directory))))

(setq create-lockfiles nil)

(auto-save-visited-mode 1)

;;; packages

(setq package-archives
      '(("gnu-elpa" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

(setq package-archive-priorities
      '(("gnu-elpa" . 3)
        ("melpa" . 2)
        ("nongnu" . 1)))

(setq package-install-upgrade-built-in t)

(load (locate-user-emacs-file "modules/looks.el"))
(load (locate-user-emacs-file "modules/minibuffer.el"))
(load (locate-user-emacs-file "modules/search.el"))
(load (locate-user-emacs-file "modules/org.el"))
(load (locate-user-emacs-file "modules/programming.el") :no-error-if-file-is-missing)
(load (locate-user-emacs-file "modules/sway.el") :no-error-if-file-is-missing)
