;;; modules/keybinds/keybinds.el -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; This is where a define my own likly insane keybindings outside
;; of the keybindings I declare inside use-package declorations.
;;
;;; Code:

;; WIP: dont even know how i feel about doing this. I think there
;; is a high chance that i should not be doing this or putting this
;; in a mode so that it can be turned on and off with ease.

;; THIS CODE SHOULD NOT BE CALLED INTO MAIN CONFIG!

(defvar-keymap custom-prefix-map
  :doc "My Custom Ergonomic Prefix"
  "C-," 'pop-global-mark
  "," 'rectangle-mark-mode
  "s" 'save-buffer
  "f" 'find-file
  "j" 'dired-jump)

(keymap-set global-map "C-," 'set-mark-command) ; remaping the set-mark-command

(keymap-set global-map "C-SPC" custom-prefix-map) ; setting new prefix key, could be changed?

