;;; init.el -- My emacs configuration -*- lexical-binding: t; mode: emacs-lisp  -*-

(require 'package)

(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/") t)

(setq custom-file (locate-user-emacs-file "custom.el"))

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(use-package emacs
  :custom
  (completion-styles '(orderless basic))
  (mac-pass-command-to-system nil)
  (make-backup-files nil)
  (mouse-wheel-progressive-speed nil)
  (ns-alternate-modifier 'none)
  (ns-command-modifier 'meta)
  (use-short-answers t)
  (ring-bell-function 'ignore)
  (global-goto-address-mode t)
  (tool-bar-mode nil)
  :custom-face
  (default ((t (:family "Aporetic Sans Mono" :height 180))))
  :config
  (setq-default line-spacing 3
		require-final-newline t)
  :bind
  (("M-`" . ns-next-frame)))

(use-package ef-themes
  :custom
  (custom-enabled-themes '(ef-light)))

;; (use-package avy
;;   :bind
;;   ("C-;" . avy-goto-char))

(use-package project
  :bind
  ("M-P" . project-find-file))

(use-package rg
  :config
  (rg-define-search rg-everything-vc-dir
    "Search for thing at point in all files within vc root."
    :query ask
    :format regexp
    :files "*"
    :dir (locate-dominating-file default-directory ".git"))
  (defun rg-dwim-mm-project ()
    (interactive)
    (if current-prefix-arg
	(call-interactively 'rg-everything-vc-dir)
      (call-interactively 'rg-dwim-project-dir)))
  :bind
  ("M-?" . rg-dwim-mm-project))

(use-package auth-source-pass
  :ensure t
  :config
  (auth-source-pass-enable))

(use-package gptel
  :demand t
  :config
  (setq gptel-model 'deepseek-coder)
  :custom
  (gptel-backend
   (gptel-make-openai "DeepSeek"
     :host "api.deepseek.com"
     :endpoint "/chat/completions"
     :stream t
     :key (auth-source-pass-get 'secret "deepseek.com")
     :models '(deepseek-chat deepseek-coder)))
  ;; (gptel-model 'o1-preview)
  ;; (gptel-backend (gptel-make-openai
  ;;                    "DeepSeek"
  ;;                  :stream t
  ;;                  :models '(gpt-4o gpt-3.5-turbo gpt-3.5-turbo-16k gpt-4
  ;; 				    gpt-4-turbo-preview gpt-4-32k gpt-4-1106-preview
  ;; 				    gpt-4-0125-preview gpt-4o-mini
  ;; 				    o1-preview o1-mini)
  ;;                  :key (auth-source-pass-get 'secret "openai.com")))
  )

(use-package consult
  :demand t
  :custom
  (consult-mode t)
  (consult-narrow-key ">")
  (consult-preview-key "M-,")
  :config
  (defun consult-ripgrep-at-point (&optional dir initial)
    "Invokes `consult-ripgrep' using symbol at point as the initial search term.

     If called with a prefix argument, grep inside the `default-directory'
     instead of project-wide."
    (interactive (list (and current-prefix-arg default-directory)
                       (when-let ((s (symbol-at-point)))
			 (symbol-name s))))
    (consult-ripgrep dir initial))
  :bind
  (("C-x ," . consult-imenu)
   ("C-x b" . consult-buffer)
   ("M-?" . consult-ripgrep-at-point)))

(use-package isearch
  :custom
  (isearch-lazy-count t)
  (lazy-count-prefix-format "(%s/%s) ")
  (lazy-count-suffix-format nil)
  (search-whitespace-regexp ".*?")
  :bind
  (("C-s" . isearch-forward)
   ("C-r" . isearch-backward)
   ("M-s ." . isearch-forward-symbol-at-point)))

(use-package xref
  :bind
  ("M-j" . xref-find-references))

(use-package orderless
  :ensure t)

(use-package vertico
  :custom
  (vertico-group-format nil)
  (vertico-mode 1)
  :bind
  (:map vertico-map
	("M-." . embark-export))
  ;;(define-key vertico-map (kbd "C-w") 'backward-kill-word)
  )

(use-package which-key
  :config
  (which-key-mode 1))

(use-package embark
  :bind
  (("C-," . embark-act)))

;; (defun my-command ()
;;   (interactive)
  
;;   )

;; (define-key embark-general-map (kbd "z") 'my-command)

(use-package embark-consult)

(use-package dired
  :hook
  (dired-mode . dired-hide-details-mode)
  :bind
  ((:map dired-mode-map
	 ("<mouse-2>" . dired-find-file)
         ("j"     . dired)
         ("z"     . pop-window-configuration)
         ("e"     . ora-ediff-files)
         ("^"     . dired-up-directory)
         ("q"     . pop-window-configuration)
         ("M-!"   . shell-command)
         ("<tab>" . dired-next-window)
         ("M-G")
         ("M-s f"))))

(use-package winner
  :demand t
  :config
  (winner-mode 1)
  :bind
  ("M-|" . winner-undo))

;; fixes macos issue: https://github.com/d12frosted/homebrew-emacs-plus/issues/383#issuecomment-899157143
;; use e.g. `nix profile install nixpkgs#coreutils-prefixed` to get the "gls" binary
(setq insert-directory-program (or (executable-find "gls") "ls"))

(use-package highlight-symbol
  :hook
  (prog-mode . highlight-symbol-nav-mode)
  (prog-mode . highlight-symbol-mode))

(use-package eglot
  :bind
  (:map eglot-mode-map
	("C-c C-r" . eglot-rename))
  :config
  (setq eglot-diagnostics-map
	(let ((map (make-sparse-keymap)))
	  (define-key map [mouse-1] #'eglot-code-actions-at-mouse)
	  map))
  (cl-loop for i from 1
           for type in '(eglot-note eglot-warning eglot-error)
           do (put type 'flymake-overlay-control
                   `((mouse-face . highlight)
                     (priority . ,(+ 50 i))
                     (keymap . ,eglot-diagnostics-map)))))

(use-package flymake
  ;; TODO: flymake-eslint ?? https://www.rahuljuliato.com/posts/eslint-on-emacs
  :config
  (advice-add 'flymake-goto-next-error :before #'eglot-code-actions-temporary-map)
  (advice-add 'eglot-code-actions :after #'eglot-code-actions-temporary-map)
  :bind
  (:map flymake-mode-map
        ("C-;" . flymake-goto-next-error)
        ("C-M-!" . flymake-show-buffer-diagnostics)))

;; (with-eval-after-load 'treemacs
;;   (define-key treemacs-mode-map [mouse-1] #'treemacs-single-click-expand-action))

(use-package emacs-lisp-mode
  :hook
  (emacs-lisp-mode . paredit-mode)
  :bind
  (:map emacs-lisp-mode-map
	("M-?")
	("C-c C-c" . eval-buffer)))

(use-package ledger-mode
  :bind
  (:map ledger-mode-map
	("C-c C-c" . ledger-report)
	("M-a" . ledger-navigate-prev-xact-or-directive)
	("M-e" . ledger-navigate-next-xact-or-directive)
	("M-RET" . ledger-start-entry))
  :config
  (when (memq window-system '(mac ns))
    (exec-path-from-shell-copy-env "LEDGER_FILE"))
  (defun ledger ()
    (interactive)
    (find-file (getenv "LEDGER_FILE"))
   (ledger-mode))
  (defun ledger-start-entry (&optional _arg)
    (interactive "p")
    (goto-char (point-max))
    (while (and (not (bobp))
		(progn (previous-line)
		       (looking-at-p "^\s*$"))))
    (forward-line)
    (delete-region (point) (point-max))
    (insert ?\n)
    (insert ?\n)
    (insert (format-time-string "%Y/%m/%d "))))

(use-package move-dup
  :bind
  (:map move-dup-mode-map
	("C-M-<up>")))

(use-package magit
  :demand t
  :after fullframe
  :bind
  ((:map magit-diff-section-map
	 ("<remap> <magit-visit-thing>" . magit-diff-visit-file-dwim)))
  :config
  (fullframe magit-status magit-mode-quit-window)

  (defun magit-diff-visit-file-dwim (file &optional goto-worktree)
    (interactive (list (magit-diff--file-at-point t t)
		       (not current-prefix-arg)))
    (if (eq major-mode 'magit-diff-mode)
	;; Generally from a diff view I want to jump straight to a
	;; file in the worktree rather than view a read-only buffer of
	;; the commit-state.
	(magit-diff-visit-file--internal file goto-worktree #'switch-to-buffer-other-window)
      (magit-diff-visit-file file)))

  (defun magit-diff-upstream ()
    (interactive)
    (magit-diff-range "@{upstream}...")))

(use-package fullframe
  :ensure t)

(use-package cider
  :bind
  (:map cider-mode-map
	("M-.") ;; Just use lsp xref
	("M-<RET>" . cider-pprint-eval-last-sexp)))

(use-package browse-kill-ring
  :ensure t
  :bind
  ("M-Y" . browse-kill-ring))

(use-package lisp
  :config
  (load (expand-file-name "~/quicklisp/slime-helper.el") t) ;; if exists
  (slime-setup '(slime-fancy))
  :hook
  (lisp-mode . paredit-mode)
  :bind
  (:map prog-mode-map
	(("C-." . mark-sexp))))

(use-package slime
  :ensure t
  :custom
  (inferior-lisp-program "sbcl")
  :bind
  (:map slime-mode-map
	(("M-." . slime-edit-definition))))

;; https://github.com/slime/slime/issues/643#issuecomment-1483709110
(with-eval-after-load 'slime
  (defun my--slime-completion-at-point ()
    (let ((slime-current-thread :repl-thread)
          (package (slime-current-package)))
      (when-let ((symbol (thing-at-point 'symbol)))
        (pcase-let ((`(,beg . ,end)
                     (bounds-of-thing-at-point 'symbol)))
          (list beg end
                (car (slime-eval
                      ;; Or swank:simple-completions
                      `(swank:fuzzy-completions
                        ,(substring-no-properties symbol) ',package))))))))
  (advice-add #'slime--completion-at-point
              :override #'my--slime-completion-at-point))

(defun slime-eval-print-last-expression-as-comment (sexp)
  "Evaluate SEXP and print the value into the current buffer as a comment."
  (interactive (list (slime-last-expression)))
  (insert " ;; => ")
  (slime-eval-print sexp))

;; TODO: investigate puni-mode https://github.com/AmaiKinono/puni

(use-package paredit
  :ensure t
  :demand t
  :bind
  (:map paredit-mode-map
	("C-k" . paredit-kill-tidy)
	("C-M-<up>" . paredit-splice-sexp-killing-backward))
  :vc (:url "https://paredit.org/paredit.git"
	    :rev :v26)
  :config
  (defun paredit-kill-tidy ()
    (interactive)
    (save-excursion
      (while (and (not (eobp))
		  (save-excursion
		    (beginning-of-line)
		    (looking-at "[\s\t]*\)")))
	(delete-indentation)))
    (paredit-kill))
  (dolist (binding '("RET" "M-s" "M-?"))
    (define-key paredit-mode-map (read-kbd-macro binding) nil))
  (define-key paredit-mode-map (kbd "C-M-<up>") 'paredit-splice-sexp-killing-backward))

(use-package clojure-ts-mode
  :config
  (setq major-mode-remap-alist
        (thread-last major-mode-remap-alist
		     (assq-delete-all 'clojurescript-mode)
		     (assq-delete-all 'clojure-mode))))

(use-package clojure-mode
  :after eglot
  :hook
  (clojure-mode . paredit-mode)
  :config
  (dolist (hook '(clojure-mode-hook))
    (add-hook hook 'eglot-ensure))
  :demand t)

(use-package ocaml-ts-mode
  :config
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
		 '(ocaml-ts-mode . ("ocamllsp")))))

(use-package nix-ts-mode
  :after reformatter
  :config
  (reformatter-define nixfmt
    :program "nixfmt"
    :lighter " nixfmt"))

(use-package j-mode
  :demand t
  :config
  (add-hook 'inferior-j-mode-hook (lambda () (electric-pair-mode -1)))
  :bind
  (:map j-mode-map
	("M-RET" . j-console-execute-line)))

(use-package typescript-ts-mode
  :demand t
  :config
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
  (add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
  :hook
  (typescript-ts-base-mode . electric-pair-mode))

;; NB. https://karthinks.com/software/a-consistent-structural-editing-interface/;; for some other structural editing considerations
(use-package combobulate
  :custom
  (combobulate-key-prefix "C-c o")
  :config
  (define-key embark-identifier-map "e" #'combobulate-edit)
  :vc (:url "https://github.com/mickeynp/combobulate"
       :rev :newest
       :branch "master"))

(use-package justl
    :bind
    ("C-x j" . justl-exec-recipe-in-dir))

(use-package markdown-mode
  :hook
  (markdown-mode . olivetti-mode))

(use-package exec-path-from-shell
  :config
  (dolist (var '("SSH_AUTH_SOCK" "SSH_AGENT_PID" "GPG_AGENT_INFO" "LANG" "LC_CTYPE" "NIX_SSL_CERT_FILE" "NIX_PATH"))
    (add-to-list 'exec-path-from-shell-variables var))
  (exec-path-from-shell-initialize))

(use-package envrc
  :config
  (envrc-global-mode)
  :ensure t)

(setq-default
   recentf-max-saved-items 1000
   recentf-exclude `("/tmp/" "/ssh:" ,(concat package-user-dir "/.*-autoloads\\.el\\'")))

(recentf-mode t)

(when (fboundp 'so-long-enable)
  (add-hook 'after-init-hook 'so-long-enable))

(setq-default history-length 1000)
(add-hook 'after-init-hook 'savehist-mode)

(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-ts-mode))

(use-package focus)

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-echo-mode t)
  :bind
  (:map corfu-map
	("C-<return>" . corfu-quit)
	([escape] . corfu-quit)
	("M-." . corfu-move-to-minibuffer)
	("M-/" . hippie-expand))
  :config
  (global-corfu-mode)

  (defun corfu-move-to-minibuffer ()
    (interactive)
    (let (completion-cycle-threshold completion-cycling)
      (apply #'consult-completion-in-region (cl-subseq completion-in-region--data 0 3)))))

(use-package eglot
  :config
  (defun eglot-code-actions-temporary-map (&rest arg)
    (set-temporary-overlay-map
     (let ((map (make-sparse-keymap)))
       (define-key map (kbd "RET") 'eglot-code-actions)
       map)
     nil))
  :custom
  (eglot-connect-timeout 3000))

(use-package whole-line-or-region
  :demand t
  :config
  (whole-line-or-region-global-mode))

(use-package delsel
  :custom
  (delete-selection-mode t))

(use-package symbol-overlay
  :ensure t
  :bind
  ("C-c C-r" . symbol-overlay-rename))

;; (use-package vterm)

(use-package hippie-exp
  :bind
  (("M-/" . hippie-expand))
  :custom
  (hippie-expand-try-functions-list
   '(try-complete-file-name-partially
     try-complete-file-name
     try-expand-dabbrev
     try-expand-dabbrev-all-buffers
     try-expand-dabbrev-from-kill)))

(use-package simple
  :config
  (defun zap-to-char-basic (arg)
    "Same as zap-to-char except either zap forward or backward by the
first occurance (not ARGth occurance)."
    (interactive "p")
    (let ((current-prefix-arg (when (equal 4 arg) '(-1))))
      ;; TODO: temporary key map with 'z' bound to repeat zap in ARG direction
      (call-interactively 'zap-to-char)))
  :bind
  ("M-z" . zap-to-char-basic))

(use-package diff-hl
  :demand t
  :config
  (diff-hl-show-hunk-mouse-mode t)
  :hook
  (prog-mode . diff-hl-mode))

(use-package diff-hl-flydiff
  :commands diff-hl-flydiff-mode
  :hook
  (prog-mode . diff-hl-flydiff-mode))

(use-package breadcrumb
  :ensure t
  :hook
  (prog-mode . breadcrumb-mode))

(use-package browse-kill-ring
  :bind
  ("M-Y" . browse-kill-ring))

(use-package mood-line
  :config
  (mood-line-mode)
  (setq mood-line-format mood-line-format-default)
  :custom
  (mood-line-glyph-alist mood-line-glyphs-fira-code))

;; Org

(use-package org-habit
  :after org-agenda
  :custom
  (org-habit-preceding-days 30)
  (org-habit-today-glyph 45))

(use-package org-agenda
  :custom
  (org-agenda-files '())
  :bind
  (("C-c a" . org-agenda)))

(use-package org
  :custom
  (org-refile-targets '((org-agenda-files :maxlevel . 3)))
  :config
  (setq org-link-frame-setup '((file . find-file)
                               (vm . vm-visit-folder)
                               (vm-imap . vm-visit-imap-folder)
                               (gnus . org-gnus-no-new-news)
                               (bbdb . bbdb)
                               (w3 . w3m-browse-url)
                               (eww . eww-browse-url)))
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((shell . t)))
  :hook
  (org-mode . turn-on-flyspell)
  :bind
  ((:map org-mode-map
	 ("C-k" . org-archive-subtree))))

(when (file-exists-p custom-file)
  (load custom-file))

;; Local Variables:
;; coding: utf-8
;; no-byte-compile: t
;; End:
;;; init.el ends here
