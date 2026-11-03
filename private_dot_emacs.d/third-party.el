;; -*- lexical-binding: t; -*-
;; ---------------------------------------------------------------------------
;; Plugins
;; ---------------------------------------------------------------------------
(use-package company
  :hook ((python-mode python-ts-mode rust-mode rust-ts-mode)
         . company-mode)
  :bind
  ("C-c ." . company-complete)
  :config
  (defun my/company-prefix-first (candidates)
    "Put matches starting with `company-prefix' before other matches."
    (if (not (stringp company-prefix))
        candidates
      (append
       (cl-remove-if-not
        (lambda (candidate)
          (string-prefix-p company-prefix candidate completion-ignore-case))
        candidates)
       (cl-remove-if
        (lambda (candidate)
          (string-prefix-p company-prefix candidate completion-ignore-case))
        candidates))))
  (add-to-list 'company-transformers #'my/company-prefix-first t))

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
  (completion-category-overrides
   '((file (styles basic partial-completion)))))

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
  :bind (("C-s"   . consult-line)
         ("C-x b" . consult-buffer)
         ("M-y"   . consult-yank-pop)
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

(use-package indent-bars
  :hook (prog-mode . indent-bars-mode)
  :bind
  ("C-c i" . indent-bars-mode))

(use-package avy :bind ("C-c j" . avy-goto-word-0))

