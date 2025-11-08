;;; early-init.el -*- lexical-binding: t; -*-
;;; Commentary:
;;
;;
;;
;;; Code:

(setq default-tab-width 4
      inhibit-startup-screen t)

(push '(menu-bar-lines . 0)   default-frame-alist)
(push '(tool-bar-lines . 0)   default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)
