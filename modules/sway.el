;;; modules/sway.el -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; Intergration with Sway! Taking alot of code form thblt. thanks thblt!
;;
;; https://github.com/thblt/sway.el
;; 
;;; Code:

(use-package sway
  :ensure t)

;; stole the idea from system crafters
(defun swaybar-get-status ()
  "Returns output that will be used by swaybar"
  "Its alive!!")

;; keymaps
(keymap-set global-map "s-w" 'sway-focus-container)
(keymap-set global-map "s-k" 'sway-kill-container)
