;;; modules/sway.el -*- lexical-binding: t; -*-
;;; Commentary:
;;
;; Intergration with Sway! Taking alot of code form thblt. thanks thblt!
;;
;; https://github.com/thblt/sway.el
;; 
;;; Code:

(defgroup sway nil
  "Communication with the Sway window manager."
  :group 'environment)

(defcustom sway-swaymsg-binary (executable-find "swaymsg")
  "Path to `swaymsg' or a compatible program."
  :type 'string
  :group 'sway)

(defun sway--validate-socket (candidate)
  "Return CANDIDATE iff it's non nil and is a readable file."
  (and candidate
       (file-readable-p candidate)
       (not (file-directory-p candidate))
       candidate))

(defun sway-find-socket ()
  "A non-subtle attempt to find the path to the Sway socket.

This isn't easy, because:
 - The same daemon can survive multiple Sway/X instances, so the
   daemon's $SWAYSOCK can be obsolete.
 - But, lucky for us, client frames get a copy on the client's
   environment as a frame parameter!
 - But, stupid Emacs doesn't copy that parameter on new frames
   created from existing client frames, eg with
   \\[make-frame-command] (this is bug #47806).  This is why we
   have `sway-socket-tracker-mode'."
  (or (sway--validate-socket (getenv "SWAYSOCK" (selected-frame)))
      ;; Note to self: on a never-pushed commit, I had an extra test:
      ;; (when (frame-parameter nil 'environment)
      ;; (getenv "SWAYSOCK" (selected-frame))))
      ;; which was probably made useless by the introduction of
      ;; `sway--validate-socket'.
      (sway--validate-socket (frame-parameter nil 'sway-socket))
      (sway--validate-socket (getenv "SWAYSOCK"))
      (error "Cannot find a valid Sway socket")))

(defun sway-json-parse-buffer ()
  "Parse current buffer as JSON, from point.

This function is just to save a few lambdas and make sure we're
reasonably consistent."
  (json-parse-buffer :null-object nil :false-object nil))

(defun sway-msg (handler message)
  "Send MESSAGE to swaymsg, writing output to HANDLER.

If HANDLER is a buffer, output is added to it.

If HANDLER is a function, output is written to a temporary
buffer, then function is run on that buffer with point at the
beginning and its result is returned.

Otherwise, output is dropped."
  (let ((buffer (or
                 (when (bufferp handler) handler)
                 (generate-new-buffer "*swaymsg*")))
        (process-environment (list (format "SWAYSOCK=%s" (sway-find-socket)))))
    (with-current-buffer buffer
      (with-existing-directory
        (call-process sway-swaymsg-binary nil buffer nil message))
      (when (functionp handler)
        (prog2
            (goto-char (point-min))
            (funcall handler)
          (kill-buffer buffer))))))

(defun sway--process-response (message response &optional handler)
  "Read RESPONSE, a parsed Sway response.

Sway responses are always a vector of statuses, because `swaymsg'
can accept multiple messages.

If none of them is an error, return nil.  Otherwise, return
output suitable for an error message, optionally passing it to
HANDLER.

MESSAGE is the message that was sent to Sway.  It is used to
annotate the error output."
  (unless handler (setq handler 'identity))

  (when (seq-some (lambda (rsp) (not (gethash "success" rsp))) response)
    ;; We have an error.
    (funcall handler
             (concat
              (format "Sway error on `%s'" message)
              (mapconcat
               (lambda (rsp)
                 (format " -%s %s"
                         (if (gethash "parse_error" rsp) " [Parse error]" "")
                         (gethash "error" rsp (format "No message: %s" rsp))))
               response
               "\n")))))

(defun sway-do (message &optional noerror)
  "Execute Sway command(s) MESSAGE.

This function always returns t or raises an error, unless NOERROR
is non-nil.  If NOERROR is a function, it is called with the
error message as its argument.

Like Sway itself, this function supports sending multiple
commands in the same message, separated by a semicolon.  It will
fail as described above if at least one of these commands return
an error."
  (let ((err
         (sway--process-response
          message
          (sway-msg 'sway-json-parse-buffer message)
          (if noerror (if (functionp noerror) noerror 'ignore) 'error))))
    err))

(defun sway-tree ()
  "Get the Sway tree as an elisp object."
  (with-temp-buffer
    (sway-msg 'sway-json-parse-buffer "-tget_tree")))

(defun sway-list-windows (&optional tree visible-only focused-only ours-only)
  "Return all windows in Sway tree TREE.

If TREE is nil, get it from `sway-tree'.

If VISIBLE-ONLY, only select visible windows.
If FOCUSED-ONLY, only select the focused window.
If OURS-ONLY, only select windows matching this Emacs' PID."
  ;; @TODO What this actually does is list terminal containers that
  ;; aren't workspaces.  The latter criterion is to eliminate
  ;; __i3_scratch, which is a potentially empty workspace.  It works,
  ;; but could maybe be improved.
  (unless tree
    (setq tree (sway-tree)))
  (let ((next-tree (gethash "nodes" tree)))
    (if (and
         (zerop (length next-tree))
         (not (string= "workspace" (gethash "type" tree)))
         (if ours-only (eq
                        (gethash "pid" tree)
                        (emacs-pid))
           t)
         (if visible-only (gethash "visible" tree) t)
         (if focused-only (gethash "focused" tree) t))
        tree ; Collect
      (flatten-tree
       (mapcar
        (lambda (t2) (sway-list-windows t2 visible-only focused-only ours-only))
        next-tree)))))

(defun sway-version ()
  "Return the Sway version number."
  (let ((json (sway-msg 'json-parse-buffer "-tget_version")))
    (list (gethash "major" json)
          (gethash "minor" json)
          (gethash "patch" json))))

;;;; Actions on containers

(defun sway-focus-container (id &optional noerror)
  "Focus Sway container ID.

ID is a Sway ID.  NOERROR is as in `sway-do', which see."
  (interactive (list
                (sway--completing-read-container "Container to focus: " t)))
  (sway-do (format "[con_id=%s] focus;" id) noerror))

(defun sway-kill-container (id &optional noerror)
  "Kill Sway container ID.

ID is a Sway ID.  NOERROR is as in `sway-do', which see."
  (interactive (list
                (sway--completing-read-container "Container to kill: " t)))
  (sway-do (format "[con_id=%s] kill;" id) noerror))

;;;; Windows and frames manipulation

(defun sway-find-x-window-frame (window)
  "Return the Emacs frame corresponding to Window, an X-Window ID.

You probably should use `sway-find-window-frame' instead.

Notice WINDOW is NOT a Sway ID, but a X id or a Sway tree objet.
If the latter, it most be the window node of a a tree

This is more of an internal-ish function.  It is used when
walking the tree to bridge Sway windows to frame objects, since
the X id is the only value available from both."
  (when (hash-table-p window)
    (setq window (gethash "window" window)))
  (seq-some (lambda (frame)
             (let ((owi (frame-parameter frame 'outer-window-id)))
               (and owi
                    (eq window (string-to-number owi))
                    frame)))
           (frame-list)))

(defun sway-find-wayland-window-frame (window)
  "Return the Emacs frame corresponding to a Sway window WINDOW.

You probably should use `sway-find-window-frame' instead.

WINDOW is a hash table, typically one of the members of
`sway-list-windows'."
  ;; A quick sanity check.
  (let ((names (seq-map (lambda (frame) (frame-parameter frame 'name))
                        (seq-filter (lambda (f)
                                      (null (frame-parameter f 'parent-frame)))
                                    (frame-list)))))
    (unless (eq (length names) (length (seq-uniq names)))
      (error "Two Emacs frames share the same name, which breaks sway.el under pgtk.  Please see README.org")))
  ;; Then
  (let ((name (gethash "name" window)))
    (seq-find (lambda (it) (equal (frame-parameter it 'name) name))
            (frame-list))))

(defun sway-find-window-frame (window)
  "Return the Emacs frame corresponding to a Sway window WINDOW.

This is a dispatcher function, it delegates to
`sway-find-x-window-frame' or `sway-find-wayland-window-frame'
depending on whether Emacs is built with pgtk."
  (if (eq window-system 'pgtk)
      (sway-find-wayland-window-frame window)
    (sway-find-x-window-frame window)))

(defun sway-find-frame-window (frame &optional tree)
  "Return the sway window id corresponding to FRAME.

FRAME is an Emacs frame object.

Use TREE if non-nil, otherwise call (sway-tree)."
  (unless tree (setq tree (sway-tree)))
  (seq-some
   (lambda (f)
     (when (eq frame (car f))
       (cdr f)))
   (sway-list-frames tree)))

(defun sway-get-id (tree)
  "Return the `id' field of TREE, a hash table."
  (gethash "id" tree))

(defun sway-list-frames (&optional tree visible-only focused-only)
  "List all Emacs frames in TREE.

VISIBLE-ONLY and FOCUSED-ONLY selects only frames that are,
respectively, visible and focused.

Return value is a list of (FRAME-OBJECT . SWAY-ID)"
  (unless tree (setq tree (sway-tree)))
  (let* ((wins (sway-list-windows tree visible-only focused-only t)))
    (mapcar (lambda (win)
              (cons (sway-find-window-frame win)
                    (sway-get-id win)))
            wins)))

(defun sway-frame-displays-buffer-p (frame buffer)
  "Determine if FRAME displays BUFFER."
  (seq-some
   (lambda (w) (eq (window-buffer w) buffer))
   (window-list frame nil)))

(defun sway-find-frame-for-buffer (buffer
                                   &optional
                                   tree visible-only focused-only)
  "Find which frame displays BUFFER.

TREE, VISIBLE-ONLY, FOCUSED-ONLY and return value are as in
`sway-list-frames', which see."
  (unless tree (setq tree (sway-tree)))
  (seq-some (lambda (f)
             (when (sway-frame-displays-buffer-p (car f) buffer)
               f))
           (sway-list-frames tree visible-only focused-only)))


(defun sway--completing-read-container (prompt &optional id-only)
  "PROMPT the user to pick a Sway container, and return its ID.

If ID-ONLY is nil of undefined, return the hashtable corresponding to
the container."
  (let* ((windows (sway-list-windows))
         ;; Alist of (formatted-window-name . hashtable)
         (alist (mapcar (lambda (it)
                          (cons
                           (format "%s (%s)"
                                   (gethash "name" it)
                                   (gethash "id" it))
                           it)) windows))
         (selected (completing-read
                    prompt
                    ;; See (info "(elisp) Programmed completion")
                    (lambda (string predicate action)
                      (if (eq action 'metadata)
                          `(metadata (category . sway-container))
                        (complete-with-action
                         action (mapcar 'car alist) string predicate)))))
         (choice (alist-get selected alist nil nil 'string=)))
    (if id-only
        (sway-get-id choice)
      choice)))

;; keymaps
(keymap-set global-map "s-w" 'sway-focus-container)
(keymap-set global-map "s-k" 'sway-kill-container)
