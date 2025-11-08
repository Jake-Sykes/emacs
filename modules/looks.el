;;; modules/looks.el -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; All the looks of my emacs, big thanks to prot for all this lol.
;;
;;; Code:

;;; Font
(set-face-attribute 'default nil :family "Iosevka" :height 120)
(set-face-attribute 'variable-pitch nil :family "Iosevka" :height 1.0) ; Need to find a font I Like for this.
(set-face-attribute 'fixed-pitch nil :family "Iosevka" :height 1.0)

;;; Theme
(use-package doric-themes
  :ensure t
  :demand t
  :config
  ;; These are the default values.
  (setq doric-themes-to-toggle '(doric-light doric-dark))
  (setq doric-themes-to-rotate doric-themes-collection)

  (doric-themes-select 'doric-light)

  ;; ;; To load a random theme instead, use something like one of these:
  ;;
  ;; (doric-themes-load-random)
  ;; (doric-themes-load-random 'light)
  ;; (doric-themes-load-random 'dark)

  :bind
  (("<f5>" . doric-themes-toggle)
   ("C-<f5>" . doric-themes-select)
   ("M-<f5>" . doric-themes-rotate)))

;;; Padding
(use-package spacious-padding
  :ensure t
  :config
  ;; These are the default values, but I keep them here for visibility.
  (setq spacious-padding-widths
	'( :internal-border-width 15
           :header-line-width 4
           :mode-line-width 6
           :tab-width 4
           :right-divider-width 30
           :scroll-bar-width 8
           :fringe-width 8))

  ;; Read the doc string of `spacious-padding-subtle-mode-line' as it
  ;; is very flexible and provides several examples.
  (setq spacious-padding-subtle-frame-lines
	`( :mode-line-active 'default
           :mode-line-inactive vertical-border))

  (spacious-padding-mode 1)

  ;; Set a key binding if you need to toggle spacious padding.
  (define-key global-map (kbd "<f8>") #'spacious-padding-mode))

;;; Modeline
;;
;; Making my own custom modeline here because I'm cool like that.
;;
;; This is super work in progress and might need to be moved to it's own file at some point
;;
;; What I wanna have in the modeline:
;; - Buffer name [x]
;; - Major mode [x]
;; - Date/time [ ]
;; - indecators for sertain actions like trap [ ]
;; - Minimal look [?]
;; - Looking good with all themes [?]
;;

(defun jds-modeline--padding (modeline-section)
  "Return modeline section with padding around it"
  (format " %s " modeline-section))

(defun jds-modeline--background (modeline-section)
  "Return modeline section with a darker? backaground"
  modeline-section) 			; Need to atualy program somthing with a point here!

;;; Buffer Name
(defvar-local jds-modeline-buffer-name
    '(:eval
      (propertize (jds-modeline--padding (buffer-name)) 'face 'bold))
  "Variable defining the buffer name section of my custom modeline.")

;;; Major Mode
(defvar-local jds-modeline-major-mode
    '(:eval
      (format "%s"
	      (propertize (jds-modeline--padding (symbol-name major-mode)) 'face 'bold)))
  "Variable defining the major-mode section of my custom modeline.")

;;; Risky Local Variables
(put 'jds-modeline--paddig 'risky-local-variable t)
(put 'jds-modeline-buffer-name 'risky-local-variable t)
(put 'jds-modeline-major-mode 'risky-local-variable t)

;;; Format
(setq-default mode-line-format
	      '("%e"
		jds-modeline-buffer-name
		jds-modeline-major-mode))
