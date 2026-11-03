;; -*- lexical-binding: t; -*-

(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                          ("org"   . "https://orgmode.org/elpa/")
                          ("elpa"  . "https://elpa.gnu.org/packages/")))
(package-initialize)

(unless package-archive-contents
  (condition-case err
      (package-refresh-contents)
    (error (message "WARNING: package-refresh-contents failed: %s" err))))

(load (expand-file-name "my-functions.el" user-emacs-directory))

;; Key bindings.
(global-set-key (kbd "M-<up>")        #'scroll-down-keep-cursor-fast)
(global-set-key (kbd "M-<down>")      #'scroll-up-keep-cursor-fast)
(global-set-key (kbd "C-c ;")         #'comment-or-uncomment-region-or-line)
(global-set-key (kbd "C-c .")         #'complete-symbol)
(global-set-key (kbd "<mouse-4>")     #'scroll-down-line)
(global-set-key (kbd "<mouse-5>")     #'scroll-up-line)
(global-set-key (kbd "C-x C-<right>") #'my/next-file-buffer)
(global-set-key (kbd "C-x C-<left>")  #'my/previous-file-buffer)
(global-set-key (kbd "C-c C-<right>") #'forward-sexp)
(global-set-key (kbd "C-c C-<left>")  #'backward-sexp)
(global-set-key (kbd "C-c C-<up>")    #'my/sexp-up)
(global-set-key (kbd "C-c C-<down>")  #'my/sexp-down)
(global-set-key (kbd "C-c n")         #'narrow-or-widen-dwim)
(global-set-key (kbd "C-c d")         #'duplicate-line-or-region)
(global-set-key (kbd "C-c k")         #'delete-whole-line)
(global-set-key (kbd "C-a")           #'smart-beginning-of-line)
(global-set-key (kbd "C-c <up>")      #'move-line-up)
(global-set-key (kbd "C-c <down>")    #'move-line-down)
(global-set-key (kbd "C-c +")         #'my/increment-digit-or-region)
(global-set-key (kbd "C-c -")         #'my/decrement-digit-or-region)
(global-set-key (kbd "C-c ]")         #'my-expand-to-parent-sexp)
(global-set-key (kbd "C-c [")         #'my-contract-sexp)

(define-prefix-command 'my-python-map)
(global-set-key (kbd "C-c p")         'my-python-map)
(global-set-key (kbd "C-c p d")       #'my-toggle-bracketed-format)

;; Custom variables
(setq custom-file (locate-user-emacs-file "custom-vars.el"))
(load custom-file 'noerror 'nomessage)
(setq history-length 25)
(setq global-auto-revert-non-file-buffers t)
(setq use-dialog-box nil)
(setq inhibit-startup-message t)
(setq visible-bell nil)
(setq show-paren-style 'mixed)
(setq initial-scratch-message "")
(setq read-file-name-completion-ignore-case t)
(setq read-buffer-completion-ignore-case t)
(setq completion-ignored-extensions (append completion-ignored-extensions '(".pyc")))
(setq scroll-conservatively 10000)
(setq scroll-step 1)

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

;; Compatibility shims - needed on Emacs 26
(unless (fboundp 'define-fringe-bitmap)
  (defun define-fringe-bitmap (&rest _)))
(unless (fboundp 'use-region-beginning)
  (defun use-region-beginning () (region-beginning)))
(unless (fboundp 'use-region-end)
  (defun use-region-end () (region-end)))

(when (display-graphic-p)
  (scroll-bar-mode -1)
  (tool-bar-mode -1)
  (tooltip-mode -1)
  (set-fringe-mode 10)
  (menu-bar-mode -1))

(column-number-mode 1)
(global-display-line-numbers-mode 0)
(setq-default indent-tabs-mode nil)
(show-paren-mode t)

(electric-pair-mode 1)
(add-hook 'python-mode-hook
    (lambda ()
        (setq-local electric-pair-inhibit-predicate
            (lambda (c) (if (char-equal c ?\") t
                (electric-pair-default-inhibit c))))))

(dolist (mode-hook '(org-mode-hook term-mode-hook shell-mode-hook eshell-mode-hook))
  (add-hook mode-hook #'my/disable-line-numbers))

;; ---------------------------------------------------------------------------
;; eglot
;; ---------------------------------------------------------------------------
(when (require 'eglot nil 'noerror)
  (add-hook 'python-mode-hook #'eglot-ensure)
  (add-hook 'rust-mode-hook #'eglot-ensure)
  (setq eglot-autoshutdown t)
  (setq eglot-sync-connect nil)
  (setq eglot-ignored-server-capabilities
        (append eglot-ignored-server-capabilities
                '(:inlayHintProvider)))
  (add-to-list 'eglot-server-programs '(python-mode . ("ty" "server")))
  (add-to-list 'eglot-server-programs '(python-ts-mode . ("ty" "server")))
  (add-to-list 'eglot-server-programs '(rust-mode . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs '(rust-ts-mode . ("rust-analyzer")))
  (add-to-list 'eglot-server-programs '(rustic-mode . ("rust-analyzer")))

  (define-prefix-command 'my-lsp-prefix-map)
  (global-set-key (kbd "C-c l") 'my-lsp-prefix-map)
  (define-key my-lsp-prefix-map (kbd "r") #'eglot-rename)
  (define-key my-lsp-prefix-map (kbd "a") #'eglot-code-actions)
  (define-key my-lsp-prefix-map (kbd "f") #'eglot-format-buffer)
  (define-key my-lsp-prefix-map (kbd "t") #'eglot-find-typeDefinition)
  (define-key my-lsp-prefix-map (kbd "d") #'eldoc-doc-buffer))

(load (expand-file-name "third-party.el" user-emacs-directory) 'noerror)
