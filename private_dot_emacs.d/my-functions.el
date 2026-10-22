;; -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------------
;; Function definitions
;; ---------------------------------------------------------------------------
(defun my/next-file-buffer ()
  "Switch to the next buffer visiting a file, skipping any non-file buffers."
  (interactive)
  (let ((start (current-buffer)))
    (next-buffer)
    (while (and (not (buffer-file-name))
                (not (eq (current-buffer) start)))
      (next-buffer))))

(defun my/previous-file-buffer ()
  "Switch to the previous buffer visiting a file, skipping any non-file buffers."
  (interactive)
  (let ((start (current-buffer)))
    (previous-buffer)
    (while (and (not (buffer-file-name))
                (not (eq (current-buffer) start)))
      (previous-buffer))))

(defun scroll-down-keep-cursor ()
  (interactive)
  (scroll-down 2))

(defun scroll-down-keep-cursor-fast ()
  (interactive)
  (scroll-down 5))

(defun scroll-up-keep-cursor ()
  (interactive)
  (scroll-up 2))

(defun scroll-up-keep-cursor-fast ()
  (interactive)
  (scroll-up 5))

(defun comment-or-uncomment-region-or-line ()
  "Comment or uncomment the region, or the current line if no active region."
  (interactive)
  (let (beg end)
    (if (region-active-p)
        (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)
    (end-of-line)
    (forward-line 1)))

(defun smart-beginning-of-line ()
  "Move point to first non-whitespace character, or BOL if already there."
  (interactive)
  (let ((oldpos (point)))
    (back-to-indentation)
    (and (= oldpos (point)) (beginning-of-line))))

(defun duplicate-line-or-region (&optional n)
  "Duplicate current line, or region if active, N times."
  (interactive "p")
  (let (beg end (origin (point)))
    (if (and (region-active-p) (> (point) (mark)))
        (exchange-point-and-mark))
    (setq beg (line-beginning-position))
    (when (region-active-p) (exchange-point-and-mark))
    (setq end (line-end-position))
    (let ((region (buffer-substring-no-properties beg end)))
      (dotimes (_ (or n 1))
        (goto-char end) (newline) (insert region) (setq end (point)))
      (goto-char (+ origin (* (length region) (or n 1)) (or n 1))))))

(defun rename-current-buffer-file ()
  "Rename current buffer and the file it is visiting."
  (interactive)
  (let* ((filename (buffer-file-name)))
    (unless (and filename (file-exists-p filename))
      (error "Buffer is not visiting a file"))
    (let ((new-name (read-file-name "New name: " (file-name-directory filename))))
      (rename-file filename new-name 1)
      (rename-buffer new-name)
      (set-visited-file-name new-name)
      (set-buffer-modified-p nil))))

(defun toggle-window-split ()
  "Swap between horizontal and vertical split for exactly two windows."
  (interactive)
  (when (= (count-windows) 2)
    (let* ((this-win-buffer (window-buffer))
           (next-win-buffer (window-buffer (next-window)))
           (this-win-edges (window-edges (selected-window)))
           (next-win-edges (window-edges (next-window)))
           (this-win-2nd (not (and (<= (car this-win-edges) (car next-win-edges))
                                    (<= (cadr this-win-edges) (cadr next-win-edges)))))
           (splitter (if (= (car this-win-edges) (car (window-edges (next-window))))
                         'split-window-horizontally
                       'split-window-vertically)))
      (delete-other-windows)
      (let ((first-win (selected-window)))
        (funcall splitter)
        (when this-win-2nd (other-window 1))
        (set-window-buffer (selected-window) this-win-buffer)
        (set-window-buffer (next-window) next-win-buffer)
        (select-window first-win)
        (when this-win-2nd (other-window 1))))))

(defun narrow-or-widen-dwim (p)
  "Widen if narrowed; else narrow to region, defun, or org subtree."
  (interactive "P")
  (cond ((and (buffer-narrowed-p) (not p)) (widen))
        ((region-active-p) (narrow-to-region (region-beginning) (region-end)))
        ((derived-mode-p 'org-mode) (org-narrow-to-subtree))
        ((derived-mode-p 'prog-mode) (narrow-to-defun))
        (t (error "Nothing to narrow to"))))

(defun delete-whole-line ()
  "Delete the whole line at point without adding it to the kill ring."
  (interactive)
  (let ((column (current-column)))
  (delete-region (line-beginning-position) (line-end-position))
  (when (eolp)
    (delete-char 1))
  (move-to-column column)))

(defun move-line--region-bounds ()
  "Return (BEG . END) covering whole lines touched by the active region.
BEG is the start of the first line in the region; END is the position
just after the last line touched by the region (including its newline),
unless the region's end sits exactly at a line start, in which case
that line is excluded (since no part of it is actually selected)."
  (let ((beg (region-beginning))
        (end (region-end)))
    (setq beg (save-excursion (goto-char beg) (line-beginning-position)))
    (setq end (save-excursion
                (goto-char end)
                (if (and (bolp) (> end beg))
                    (point)
                  (line-beginning-position 2))))
    (cons beg end)))

(defun move-line--internal (direction)
  "Move the current line, or all lines touched by the region, by DIRECTION.
DIRECTION is -1 to move up, 1 to move down."
  (if (use-region-p)
      (let* ((bounds (move-line--region-bounds))
             (beg (car bounds))
             (end (cdr bounds))
             (point-at-end (> (point) (mark))))
        (cond
         ((and (< direction 0) (= beg (point-min)))
          (user-error "Cannot move region up: already at the top"))
         ((and (> direction 0) (= end (point-max)) (not (eq (char-before end) ?\n)))
          (user-error "Cannot move region down: already at the bottom"))
         (t
          (let ((text (delete-and-extract-region beg end)))
            (goto-char beg)
            (forward-line direction)
            (let ((new-beg (point)))
              (insert text)
              (if point-at-end
                  (progn (push-mark new-beg t t)
                         (goto-char (+ new-beg (- end beg))))
                (progn (goto-char new-beg)
                       (push-mark (+ new-beg (- end beg)) t t)))
              (setq deactivate-mark nil))))))
    (let ((col (current-column)))
      (if (< direction 0)
          (progn (transpose-lines 1) (forward-line -2))
        (progn (forward-line 1) (transpose-lines 1) (forward-line -1)))
      (move-to-column col))))

(defun move-line-up ()
  "Swap the current line, or all lines touched by the region, with the line(s) above."
  (interactive)
  (move-line--internal -1))

(defun move-line-down ()
  "Swap the current line, or all lines touched by the region, with the line(s) below."
  (interactive)
  (move-line--internal 1))

 
(defun my/incdec-digit-or-region (delta)
  "If region is active and contains a plain integer, inc/dec it by DELTA.
Otherwise, inc/dec the single digit at point by DELTA (no wraparound).
If the result no longer fits in a single digit (e.g. 9 -> 10, or 0 -> -1),
insert the new value and activate the region over it, so a following
call will operate on the whole number via the region branch."
  (if (use-region-p)
      (let* ((start (region-beginning))
             (end (region-end))
             (text (string-trim (buffer-substring-no-properties start end))))
        (unless (string-match-p "\\`-?[0-9]+\\'" text)
          (user-error "Region does not contain a plain integer"))
        (let* ((new-val (+ (string-to-number text) delta))
               (new-text (number-to-string new-val)))
          (delete-region start end)
          (goto-char start)
          (insert new-text)
          (push-mark start)
          (activate-mark)))
    (unless (and (char-after) (string-match-p "[0-9]" (string (char-after))))
      (user-error "No digit under point"))
    (let* ((pos (point))
           (digit (- (char-after pos) ?0))
           (new-val (+ digit delta))
           (new-text (number-to-string new-val)))
      (delete-char 1)
      (insert new-text)
      (if (= (length new-text) 1)
          ;; Still a single digit: no region, point stays put.
          (goto-char pos)
        ;; Overflowed to multiple chars (e.g. "10" or "-1"): select it.
        (let ((end (point)))
          (goto-char pos)
          (push-mark end)
          (activate-mark)
          (goto-char end))))))

(defun my/increment-digit-or-region (&optional n)
  "Increment digit at point by N (default 1), or region's integer if active."
  (interactive "p")
  (my/incdec-digit-or-region (or n 1)))

(defun my/decrement-digit-or-region (&optional n)
  "Decrement digit at point by N (default 1), or region's integer if active."
  (interactive "p")
  (my/incdec-digit-or-region (- (or n 1))))

(defvar-local my/sexp-nav-stack nil
  "Stack of markers recording point's position just before each
`my/sexp-up' move, so `my/sexp-down' can retrace the same path.")

(add-hook 'post-command-hook #'my/sexp-nav-maybe-reset)

(defun my/sexp-up (&optional arg)
  "Like `backward-up-list', but remember where point was each time,
so `my/sexp-down' can descend back to exactly that spot."
  (interactive "p")
  (dotimes (_ (or arg 1))
    (push (point-marker) my/sexp-nav-stack)
    (backward-up-list)))

(defun my/sexp--marker-in-next-sexp-p (marker)
  "Non-nil if MARKER lies within the sexp `down-list' would enter next."
  (condition-case nil
      (save-excursion
        (down-list)
        (let* ((open-pos (1- (point)))
               (close-pos (scan-sexps open-pos 1)))
          (and close-pos
               (<= open-pos (marker-position marker) close-pos))))
    (error nil)))

(defun my/sexp-down (&optional arg)
  "Like `down-list', but if the top of `my/sexp-nav-stack' sits inside
the sexp about to be entered, jump straight back to that remembered
position instead of just descending to the nearest subform."
  (interactive "p")
  (dotimes (_ (or arg 1))
    (let ((target (car my/sexp-nav-stack)))
      (if (and target
               (marker-buffer target)
               (eq (marker-buffer target) (current-buffer))
               (my/sexp--marker-in-next-sexp-p target))
          (progn
            (pop my/sexp-nav-stack)
            (goto-char (marker-position target))
            (set-marker target nil))
        (down-list)))))

(defun my/sexp-nav-reset ()
  "Clear the up/down navigation history."
  (interactive)
  (dolist (m my/sexp-nav-stack) (set-marker m nil))
  (setq my/sexp-nav-stack nil))

(defun my/sexp-nav-maybe-reset ()
  "Reset `my/sexp-nav-stack' unless the just-run command was part of
the up/down navigation sequence."
  (unless (memq this-command '(my/sexp-up my/sexp-down))
    (when my/sexp-nav-stack
      (my/sexp-nav-reset))))



;; keep this at the end!
(provide 'my-functions)
