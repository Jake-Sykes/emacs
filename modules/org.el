;;; modules/org.el -*- lexical-binding: t; -*-
;;; Commentary:
;;
;;
;;
;;; Code:

(defun jds/org-mode-setup ()
  (visual-line-mode 1)
  (variable-pitch-mode 1)
  (org-indent-mode 1)
  (auto-fill-mode 1))

(add-hook 'org-mode-hook 'jds/org-mode-setup)
