;; -*- lexical-binding: t; -*-

;; ---------------------------------------------------------------------------
;; Package bootstrap
;; ---------------------------------------------------------------------------
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                          ("org"   . "https://orgmode.org/elpa/")
                          ("elpa"  . "https://elpa.gnu.org/packages/")))
(package-initialize)

(unless package-archive-contents
  (condition-case err
      (package-refresh-contents)
    (error (message "WARNING: package-refresh-contents failed: %s" err))))

(unless (fboundp 'use-package)
  (unless (package-installed-p 'use-package)
    (condition-case err
        (package-install 'use-package)
      (error (message "WARNING: could not install use-package: %s" err)))))

(require 'use-package)
(setq use-package-always-ensure t)
(add-to-list 'load-path (locate-user-emacs-file "lisp"))

;; ---------------------------------------------------------------------------
;; Core Emacs settings
;; ---------------------------------------------------------------------------
(use-package emacs
  :bind (("M-<up>"         . scroll-down-keep-cursor-fast)
         ("M-<down>"       . scroll-up-keep-cursor-fast)
         ("C-c ;"          . comment-or-uncomment-region-or-line)
         ("C-c ."          . complete-symbol)
         ("<mouse-4>"      . scroll-down-line)
         ("<mouse-5>"      . scroll-up-line)
         ("C-x C-<right>"  . my/next-file-buffer)
         ("C-x C-<left>"   . my/previous-file-buffer)
         ("C-c C-<right>"  . forward-sexp)
         ("C-c C-<left>"   . backward-sexp)
         ("C-c d"          . duplicate-line-or-region)
         ("C-x 4 t"        . toggle-window-split)
         ("C-c n"          . narrow-or-widen-dwim)
         ("C-a"            . smart-beginning-of-line))

  :bind-keymap (("C-c l" . my-lsp-prefix-map)
                ("C-c D" . my-diagnostics-map))

  :custom
  ;; Keep Custom's generated settings out of this file.
  (custom-file (locate-user-emacs-file "custom-vars.el"))
  (history-length 25)
  (global-auto-revert-non-file-buffers t)
  (use-dialog-box nil)
  (inhibit-startup-message t)
  (visible-bell nil)
  (show-paren-style 'mixed)
  (initial-scratch-message "")
  (read-file-name-completion-ignore-case t)
  (read-buffer-completion-ignore-case t)
  (completion-ignored-extensions (append completion-ignored-extensions '(".pyc")))
  (scroll-conservatively 10000)
  (scroll-step 1)

  :init
  (define-prefix-command 'my-lsp-prefix-map)
  (define-prefix-command 'my-diagnostics-map)

  ;; Support opening new minibuffers from inside existing minibuffers
  (setq enable-recursive-minibuffers t)
  ;; Hide commands in M-x which do not work in the current mode
  (setq read-extended-command-predicate #'command-completion-default-include-p)
  ;; Don't allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))

  ;; custom-file is set via :custom above, which runs before :init, so safe here.
  (load custom-file 'noerror 'nomessage)

  (savehist-mode 1)
  (save-place-mode 1)
  (global-auto-revert-mode 1)
  (cua-selection-mode t)
  (windmove-default-keybindings)

  ;; Keep backup, autosave, and lock files out of project directories.
  (let ((backup-dir    (locate-user-emacs-file "backups/"))
        (auto-save-dir (locate-user-emacs-file "autosaves/"))
        (lock-dir      (locate-user-emacs-file "locks/")))
    (dolist (dir (list backup-dir auto-save-dir lock-dir))
      (make-directory dir t))
    (setq backup-directory-alist `(("." . ,backup-dir))
          auto-save-file-name-transforms `((".*" ,auto-save-dir t))
          lock-file-name-transforms `((".*" ,lock-dir t))
          auto-save-list-file-prefix (expand-file-name ".saves-" auto-save-dir)))

  ;; Compatibility shims - needed on Emacs 26 at work.
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
  (setq-default indent-tabs-mode nil) ;; FIXED: not a minor-mode function, just a variable.
  (show-paren-mode t)
  (electric-pair-mode 1)

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

  :hook
  ((org-mode term-mode shell-mode eshell-mode) . my/disable-line-numbers))

;; ---------------------------------------------------------------------------
;; eglot
;; ---------------------------------------------------------------------------
(use-package eglot
  :ensure nil
  :config
  (setq eglot-ignored-server-capabilities
        (append eglot-ignored-server-capabilities
                '(:inlayHintProvider)))
  (add-to-list 'eglot-server-programs '(python-mode . ("ty" "server")))
  (add-to-list 'eglot-server-programs '(rust-mode . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs '(rust-ts-mode . ("rust-analyzer"))))

;; ---------------------------------------------------------------------------
;; Plugins
;; ---------------------------------------------------------------------------
(use-package company
  :init (company-mode 1))

(use-package which-key
  :init (which-key-mode 1))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package multiple-cursors
  :init (multiple-cursors-mode)
  :bind (("C-d"   . mc/mark-next-like-this)
         ("C-S-d" . mc/mark-all-like-this)))

;; -----------------------------
;; Vertico — minimalist vertical completion UI
;; -----------------------------
(use-package vertico
  :init
  (vertico-mode 1)
  :custom
  (vertico-count 15)          ; number of candidates shown
  (vertico-resize t)
  (vertico-cycle t))

;; Needed for Vertico to work well with Emacs' built-in completion
(use-package savehist
  :init
  (savehist-mode 1))

;; -----------------------------
;; Orderless — flexible fuzzy/space-separated matching
;; -----------------------------
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; -----------------------------
;; Marginalia — rich annotations in the minibuffer
;; -----------------------------
(use-package marginalia
  :init
  (marginalia-mode 1))

;; -----------------------------
;; Consult — enhanced search/navigation commands
;; -----------------------------
(use-package consult
  :bind (("C-s" . consult-line)
         ("C-x b" . consult-buffer)
         ("M-y" . consult-yank-pop)
         ("M-g g" . consult-goto-line)
         ("M-g i" . consult-imenu)
         ("M-g f" . consult-flymake)
         ("C-c g" . consult-ripgrep)
         ("C-c f" . consult-find))
  :custom
  (consult-narrow-key "<"))

;; -----------------------------
;; Embark — contextual actions
;; -----------------------------
(use-package embark
  :bind (("C-c a" . embark-act)
         ("C-c e" . embark-dwim)
         ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Integration between Embark and Consult
(use-package embark-consult
  :after (embark consult)
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package rust-ts-mode
  :if (and (fboundp 'treesit-available-p) (treesit-available-p))
  :mode ("\\.rs\\'" . rust-ts-mode)
  :init
  (require 'treesit)
  (unless (treesit-language-available-p 'rust)
    (treesit-install-language-grammar 'rust)))

(use-package indent-bars :hook (prog-mode . indent-bars-mode))

(use-package avy :bind ("C-c j" . avy-goto-word-0))

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

