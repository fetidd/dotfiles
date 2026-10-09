;; -*- lexical-binding: t; -*-

;; set-up packaging
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(require 'use-package)
;; this makes the default for use-package to always ensure each package is installed
;; (setq use-package-always-ensure t)
(add-to-list 'load-path (locate-user-emacs-file "lisp"))

;; core emacs settings
(use-package emacs
  :bind
  ("M-<up>"        . scroll-down-keep-cursor-fast)
  ("M-<down>"      . scroll-up-keep-cursor-fast)
  ("C-c d"         . duplicate-line)
  ("C-c ;"         . comment-or-uncomment-region-or-line)
  ("C-c ."         . complete-symbol)
  ("<mouse-4>"     . scroll-down-line)
  ("<mouse-5>"     . scroll-up-line)
  ("C-x C-<right>" . my/next-file-buffer)
  ("C-x C-<left>"  . my/previous-file-buffer)
  ("C-c <C-right"  . forward-sexp-function)
  ("C-c <C-left"   . backward-sexp-function)

  :init
  (define-prefix-command 'my-lsp-prefix-map)
  (define-prefix-command 'my-diagnostics-map)
  (load custom-file 'noerror 'nomessage)
  (savehist-mode 1)
  (save-place-mode 1)
  (global-auto-revert-mode 1)
  ;; Allows doing rectangular selects, overwriteing selected etc.
  (cua-selection-mode t)
  ;; rebinds shift from above to easily move between windows with arrow keys
  (windmove-default-keybindings)

  ;; Keep backup, autosave, and lock files out of project directories.
  (let ((backup-dir (locate-user-emacs-file "backups/"))
        (auto-save-dir (locate-user-emacs-file "autosaves/"))
        (lock-dir (locate-user-emacs-file "locks/")))
    (dolist (dir (list backup-dir auto-save-dir lock-dir))
      (make-directory dir t))
    (setq backup-directory-alist `(("." . ,backup-dir))
          auto-save-file-name-transforms `((".*" ,auto-save-dir t))
          lock-file-name-transforms `((".*" ,lock-dir t))
          auto-save-list-file-prefix (expand-file-name ".saves-" auto-save-dir)))

  ;; compatibility shims - use v26 in work which uses old definitions
  (unless (fboundp 'define-fringe-bitmap)
    (defun define-fringe-bitmap (&rest _)))
  (unless (fboundp 'use-region-beginning)
    (defun use-region-beginning () (region-beginning)))
  (unless (fboundp 'use-region-end)
    (defun use-region-end () (region-end)))


  ;; Appearance.
  (set-face-attribute 'default nil
                      :font "JetBrainsMono Nerd Font Mono"
                      :height 110)
  (load-theme 'modus-vivendi t)
  (scroll-bar-mode -1)
  (tool-bar-mode -1)
  (tooltip-mode -1)
  (set-fringe-mode 10)
  (menu-bar-mode -1)
  (column-number-mode 1)
  (global-display-line-numbers-mode 0)
  ;; Turn off use of tabs for indentation in many modes
  (indent-tabs-mode nil)
  ;; turn on paren matching
  (show-paren-mode t)
  (electric-pair-mode 1)

  :bind-keymap (("C-c l" . my-lsp-prefix-map)
                ("C-c D" . my-diagnostics-map))

  :config
  ;; LSP (eglot) commands
  (define-key my-lsp-prefix-map (kbd "r") #'eglot-rename)
  (define-key my-lsp-prefix-map (kbd "a") #'eglot-code-actions)
  (define-key my-lsp-prefix-map (kbd "f") #'eglot-format-buffer)
  (define-key my-lsp-prefix-map (kbd "t") #'eglot-find-typeDefinition)
  (define-key my-lsp-prefix-map (kbd "d") #'eldoc-doc-buffer)

  ;; Diagnostics commands (flymake)
  (define-key my-diagnostics-map (kbd "l") #'flymake-show-buffer-diagnostics)
  (define-key my-diagnostics-map (kbd "n") #'flymake-goto-next-error)
  (define-key my-diagnostics-map (kbd "p") #'flymake-goto-prev-error)
  (define-key my-diagnostics-map (kbd "a") #'flymake-show-project-diagnostics)

  :custom
  ;; Keep Custom's generated settings out of this file.
  (custom-file (locate-user-emacs-file "custom-vars.el"))
  ;; Save what is entered into minibuffer prompts.
  (history-length 25)
  ;; Revert non-file buffers as well as changed files.
  (global-auto-revert-non-file-buffers t)
  ;; Avoid graphical prompts and startup noise.
  (use-dialog-box nil)
  (inhibit-startup-message t)
  (visible-bell nil)
  (show-paren-style 'mixed)
  (initial-scratch-message "")
  ;; Dont show the GNU splash screen
  (inhibit-startup-message t)
  ;; Ignore case
  (read-file-name-completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  ;; Hide .pyc from the list of filename completions
  (completion-ignored-extensions (append completion-ignored-extensions (quote (".pyc"))))
  ;; scroll just one line when hitting bottom of the window
  (scroll-conservatively 10000)
  ;; keyboard scroll one line at a time
  (scroll-step 1) 
  
  :hook
  ((org-mode term-mode shell-mode eshell-mode) . my/disable-line-numbers)
  )


(use-package eglot
  :ensure nil
  :config
  (setq eglot-ignored-server-capabilities
        (append eglot-ignored-server-capabilities
                '(:inlayHintProvider)))
  (add-to-list 'eglot-server-programs '(python-mode . ("ty" "server")))
  (add-to-list 'eglot-server-programs '(rust-mode . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs '(rust-ts-mode . ("rust-analyzer"))))






;#############
;## PLUGINS ##
;#############

;; code completion
(use-package company :init (company-mode))

;; which-key shows possible next keys for chords
(use-package which-key
  :init (which-key-mode 1))

;; make pairs of parens visually distinguishable
(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; extra context in the minibuffer
(use-package marginalia
  :init
  (marginalia-mode))

;; sort of like VSCode's multiple cursor selection, but only works on a single 'page' of a buffer
(use-package multiple-cursors
  :init
  (multiple-cursors-mode)
  :bind
  ("C-d" . 'mc/mark-next-like-this)
  ("C-S-d" . 'mc/mark-all-like-this))

;; powerful minibuffer completion
(use-package helm
  :demand t
  :bind (("M-x"     . helm-M-x)
         ("C-x C-f" . helm-find-files)
         ("C-x b"   . helm-mini)
         ("M-y"     . helm-show-kill-ring))
  :config
  (require 'helm-mode)
  (helm-mode 1))






;#########################
;## FUNCTION DEFINITONS ##
;#########################

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

;; Scroll the text one line down while keeping the cursor
(defun scroll-down-keep-cursor ()
  (interactive)
  (scroll-down 2))

(defun scroll-down-keep-cursor-fast ()
  (interactive)
  (scroll-down 5))

;; Scroll the text one line up while keeping the cursor
(defun scroll-up-keep-cursor ()
  (interactive)
  (scroll-up 2))

(defun scroll-up-keep-cursor-fast ()
  (interactive)
  (scroll-up 5))

;; Comments or uncomments the region or the current line if there's no active region, leaving point in lower line
(defun comment-or-uncomment-region-or-line ()
  (interactive)
  (let (beg end)
    (if (region-active-p)
      (setq beg (region-beginning) end (region-end))
      (setq beg (line-beginning-position) end (line-end-position)))
    (comment-or-uncomment-region beg end)
    (end-of-line)
    (next-line)))

;; Duplicate current line, leaving point in lower line
(defun duplicate-line (arg)
    (interactive "*p")
      (setq buffer-undo-list (cons (point) buffer-undo-list))
      (let ((beg (save-excursion (beginning-of-line) (point))) end)
	   (save-excursion
	     (end-of-line)
	     (setq end (point))
	     (let ((line (buffer-substring beg end)) (buffer-undo-list t) (count arg))
	          (while (> count 0)
		    (newline)
                    (insert line)
                    (setq count (1- count))))
	     (setq buffer-undo-list (cons (cons end (point)) buffer-undo-list))))
      (end-of-line)
      (next-line arg))
