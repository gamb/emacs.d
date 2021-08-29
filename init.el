;;; init.el --- My Emacs configuration -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/") t)

(when (fboundp 'menu-bar-mode)
  (menu-bar-mode -1))

(if window-system
    (tool-bar-mode -1))

(fset 'yes-or-no-p 'y-or-n-p)

(defconst *is-a-mac* (eq system-type 'darwin))

(defconst *org-files-directory* (expand-file-name "org-files" user-emacs-directory))

(defconst *snippets-directory* (expand-file-name "snippets" user-emacs-directory))

(setq gc-cons-threshold (* 128 1024 1024))
(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 20 1024 1024))))

(use-package exec-path-from-shell
  :config
  (with-eval-after-load 'exec-path-from-shell
    (dolist (var '("SSH_AUTH_SOCK" "SSH_AGENT_PID" "GPG_AGENT_INFO" "LANG" "LC_CTYPE" "NIX_SSL_CERT_FILE" "NIX_PATH"))
      (add-to-list 'exec-path-from-shell-variables var)))
  (exec-path-from-shell-initialize))

(use-package geiser-chicken
  :custom
  (geiser-chicken-binary "csi")
  :config
  ;; Override geiser-chicken--version. Instead of call-process in a
  ;; temp-buffer, use shell-command-to-string, as this is compatible
  ;; with envrc. See: https://github.com/purcell/envrc/issues/12#issuecomment-755786124
  (eval-after-load "geiser"
    '(defun geiser-chicken--version (binary)
       "Find Chicken's version using  BINARY."
       (shell-command-to-string (format
                                 "%s %s" binary "-e '(display \
                     (or (handle-exceptions exn \
                           #f \
                           (eval `(begin (import chicken.platform) \
                                         (chicken-version)))) \
                         (chicken-version)))'")))))

(use-package nix-mode
  :bind (("C-c"))
  :mode "\\.nix\\'")

(use-package nix-sandbox)

(use-package nix-buffer)

(use-package eglot)


(use-package diminish)

(use-package treemacs
  :bind (("C-x t" . treemacs)
         :map treemacs-mode-map
         ("s" . treemacs-switch-workspace)
         ("a" . treemacs-add-project-to-workspace)))

(use-package wgrep
  :defer 5)

;; TODO possible to automatically run ispell on git commit messages / pre-commit
(use-package magit
  :after (fullframe)
  :config
  (fullframe magit-status magit-mode-quit-window)
  :custom
  (magit-save-repository-buffers t)
  :bind (("C-x l" . magit-log-buffer-file)
         ("C-x g" . magit-status)))

(use-package reformatter)

(use-package company
  :custom
  (company-show-numbers t)
  :bind (("M-/" . company-complete)
         :map company-active-map
         ("M-/" . company-other-backend)
         ("C-n" . company-select-next)
         ("C-p" . company-select-previous))
  :config
  (global-company-mode))

(use-package purescript-mode
  :config
  (reformatter-define purty
    :program "purty"
    :lighter " purty"
    :args '("-"))
  :hook
  ((purescript-mode . company-mode)
   (purescript-mode . purty-on-save-mode)
   (purescript-mode . turn-on-purescript-indentation)))

(use-package psc-ide
  :config
  (add-hook 'purescript-mode-hook #'psc-ide-mode))

(use-package haskell-mode
  :after (reformatter)
  :config
  (reformatter-define ormolu
    :program "ormolu"
    :lighter " Orm")
  :hook
  ((haskell-mode . ormolu-on-save-mode)))

(use-package envrc
  :hook (after-init . envrc-global-mode))

(use-package dhall-mode
  :mode "\\.dhall\\'")

(use-package vertico
  :init
  (vertico-mode)
  :bind (:map vertico-map
              ("C-w" . backward-kill-word)
              ("C-v" . vertico-scroll-up)))

(use-package orderless
  :init
  (setq completion-styles '(orderless)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package terraform-mode
  :init)

(use-package company-terraform
  :config (company-terraform-init))

(use-package projectile
  :hook (after-init . projectile-mode)
  :config
  (when (executable-find "rg")
    (setq-default projectile-generic-command "rg --files --hidden"))
  :custom
  (projectile-completion-system 'auto)
  (projectile-mode-line-prefix " Proj")
  (projectile-tags-file-name "PROJECT_TAGS")
  :bind
  (:map projectile-mode-map (("C-c p" . projectile-command-map))))

(use-package fullframe)

(use-package ibuffer
  :after (fullframe)
  :bind
  (("C-x C-b" . ibuffer))
  :config
  (fullframe ibuffer ibuffer-quit))

(use-package typescript-mode
  :mode "\\(\\.tsx?\\)$")

(use-package swiper
  :bind ("C-M-s" . swiper-thing-at-point))

(use-package consult
  :init
  (setq register-preview-delay 0
        register-preview-function #'consult-register-format)

  (advice-add #'register-preview :override #'consult-register-window)

  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  :config
  (consult-customize
   consult-theme
   :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-file consult--source-project-file consult--source-bookmark
   :preview-key (kbd "M-P"))
  (setq consult-narrow-key "<") ;; (kbd "C-+")
  (setq consult-project-root-function
        (lambda ()
          (when-let (project (project-current))
            (car (project-roots project)))))
)

(use-package marginalia
  :ensure t
  :config
  (marginalia-mode))

;; TODO Possible to use Paredit to work more effectively with JSX?
;; TODO Try opening zipped dependencies in: TIDE https://github.com/ananthakumaran/tide/issues/388

(use-package tide
  :after (typescript-mode company)
  :bind (("C-c M-s" . tide-organize-imports)
         ("C-c C-c" . tide-project-errors))
  :custom
  (tide-always-show-documentation t)
  (tide-filter-out-warning-completions t)
  ;; Nb. JSX completion https://github.com/ananthakumaran/tide/issues/334
  (tide-server-max-response-length 4284928)
  :config
  (reformatter-define prettier
    :program "prettier"
    :args '("--parser" "typescript"))
  :hook ((typescript-mode . tide-setup)
         (typescript-mode . prettier-on-save-mode)))

(use-package flycheck
  :custom
  (flycheck-display-errors-delay 0.2)
  :bind
  (("M-g l" . flycheck-list-errors))
  :config
  (add-hook 'flycheck-error-list-after-refresh-hook
            (lambda ()
              "Auto-adjust error list to fit contents."
              (-when-let (window (flycheck-get-error-list-window t))
                (with-selected-window window
                  (fit-window-to-buffer window 30)))))
  :init (global-flycheck-mode))

(use-package flycheck-inline
  :after flycheck
  :config (global-flycheck-inline-mode))

(use-package attrap
  :ensure t
  :bind (("C-x /" . attrap-attrap)))

(use-package rainbow-delimiters)

(use-package rainbow-mode
  :hook ((prog-mode-hook . rainbow-mode)))

(use-package cider
  :custom
  (nrepl-log-messages t)
  (nrepl-popup-stacktraces nil)
  :hook ((cider-mode-hook . eldoc-mode)
         (cider-repl-mode-hook . eldoc-mode)
         (cider-repl-mode-hook . paredit-mode)
         (cider-repl-mode-hook . rainbow-delimiters-mode)))

(use-package clojure-mode
  :hook ((clojure-mode-hook . rainbow-delimiters-mode)))

(use-package avy
  :ensure t
  :bind (("C-;" . avy-goto-char-timer)))

(use-package move-dup
  :config
  (global-set-key (kbd "M-<up>") 'move-dup-move-lines-up)
  (global-set-key (kbd "M-<down>") 'move-dup-move-lines-down)
  (global-set-key (kbd "C-M-<up>") 'move-dup-duplicate-up)
  (global-set-key (kbd "C-M-<down>") 'move-dup-duplicate-down)
  (global-set-key (kbd "C-c d") 'md-duplicate-down)
  (global-set-key (kbd "C-c u") 'md-duplicate-up)
  :init
  (global-move-dup-mode))

(use-package vterm
  :bind
  ;; Remap C-w or we'll get a read-only buffer error.
  ;; See https://github.com/akermu/emacs-libvterm/issues/156
  ;; Also seemed to need to do this for yank, probably doing something wrong here.
  (:map vterm-mode-map
        ([remap whole-line-or-region-kill-region] . vterm-send-C-w)
        ("C-y" . vterm-yank)))

(use-package emacs
  :custom-face
  (default ((t (:inherit nil :extend nil :stipple nil :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 160 :width normal :foundry "nil" :family "IBM Plex Mono")))))

(use-package org
  :custom
  (org-agenda-files (cons *org-files-directory* nil))
  (org-link-frame-setup '((vm . vm-visit-folder-other-frame)
                          (vm-imap . vm-visit-imap-folder-other-frame)
                          (gnus . org-gnus-no-new-news)
                          (file . find-file)
                          (wl . wl-other-frame)))
  (org-hide-emphasis-markers t)
  (org-hide-leading-stars t)
  :custom-face
  ;; Lots of nice customizations cherry picked from https://mstempl.netlify.app/post/beautify-org-mode/
  (org-document-title ((t (:weight bold :height 1.5))))
  (org-level-1 ((t (:inherit outline-1 :extend nil :height 1.5))))
  (org-level-2 ((t (:inherit outline-1 :extend nil :height 1.3))))
  (org-level-3 ((t (:inherit outline-1 :extend nil :height 1.2))))
  (org-level-4 ((t (:inherit outline-1 :extend nil :height 1.1))))
  (org-block                 ((t (:inherit fixed-pitch))))
  (org-document-info-keyword ((t (:inherit (shadow fixed-pitch)))))
  (org-property-value        ((t (:inherit fixed-pitch))))
  (org-special-keyword       ((t (:inherit (font-lock-comment-face fixed-pitch)))))
  (org-tag                   ((t (:inherit (shadow fixed-pitch) :weight bold))))
  (org-verbatim              ((t (:inherit (shadow fixed-pitch)))))
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((python . t)
     (emacs-lisp . t)
     (lisp . t)
     (scheme . t)
     (ocaml . t)
     (haskell . t)))
  :hook ((org-mode . visual-line-mode)
         (org-mode . variable-pitch-mode)
         (org-mode . org-indent-mode))
  :bind (("C-c a" . org-agenda)
         :map org-mode-map
         (("M-." . org-open-at-point)
          ("M-," . org-mark-ring-goto))))

(add-to-list 'load-path (expand-file-name "~/.opam/default/share/emacs/site-lisp/tuareg.el"))


(use-package rg
  :config
  (global-set-key (kbd "M-?") 'rg-project))

(use-package affe
  :config
  (when (executable-find "rg")
    (defun gamb/affe-grep-at-point (initial-input &optional use-current-dir)
      ;; This is ported over from `sanityinc/counsel-search-project
      (interactive (list (let ((sym (thing-at-point 'symbol)))
                           (when sym (regexp-quote sym)))
			 current-prefix-arg))
      (let ((current-prefix-arg)
            (dir (if use-current-dir
                     default-directory
                   (condition-case err
                       (projectile-project-root)
                     (error default-directory)))))
	(funcall 'affe-grep dir initial-input)))
    (global-set-key (kbd "M-?") 'gamb/affe-grep-at-point)))

(use-package fsharp-mode
  :defer t
  :ensure t)

(use-package eglot-fsharp
  :defer t
  :ensure t)

(use-package org-roam
  :custom
  (org-roam-v2-ack t)
  (org-roam-graph-viewer (or (executable-find "open") (executable-find "firefox")))
  (org-roam-graph-executable "neato")
  (org-roam-graph-node-extra-config nil)
  (org-roam-graph-extra-config '(("overlap" . "false")))
  (org-roam-directory "~/Projects/learning")
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n c" . org-roam-capture)
         ("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert))
  :config
  (org-roam-setup))

;; Enables shortcut hints during M-x completion
(when (commandp 'counsel-M-x)
  (global-set-key [remap execute-extended-command] #'counsel-M-x))

(global-set-key [f6] 'recompile)

;; Shortcut to open this file
(defun open-init-file ()
  "Jump to init.el."
  (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

(global-set-key (kbd "C-c e") #'open-init-file)

;; Common Lisp
(use-package slime
  :commands slime
  :config
  (with-eval-after-load 'slime-repl
    (define-key slime-repl-mode-map (kbd "C-p") 'slime-repl-previous-input)
    (define-key slime-repl-mode-map (kbd "C-n") 'slime-repl-next-input))
  :init
  (setq inferior-lisp-program "nix-shell -p sbcl --run sbcl"))

;; JavaScript
(use-package skewer-mode
  :ensure t)

;; Editing...

;; Overwrite selection when typing
(add-hook 'after-init-hook 'delete-selection-mode)

(add-hook 'after-init-hook 'global-auto-revert-mode)
(setq global-auto-revert-non-file-buffers t
      auto-revert-verbose nil)
(with-eval-after-load 'autorevert
  (diminish 'auto-revert-mode))

(add-hook 'after-init-hook 'transient-mark-mode)

;; Manage huge files
(when (fboundp 'so-long-enable)
  (add-hook 'after-init-hook 'so-long-enable))

;; Typing an open parenthesis automatically inserts the corresponding
;; closing parenthesis
(when (fboundp 'electric-pair-mode)
  (add-hook 'after-init-hook 'electric-pair-mode))
(add-hook 'after-init-hook 'electric-indent-mode)

;; Cut/copy the current line if no region is active (C-w)
(use-package whole-line-or-region
  :hook (after-init . whole-line-or-region-global-mode))

;; Display keybindings following M-x commands
(use-package which-key
  :hook (after-init . which-key-mode))

;; OSK Keys
(when *is-a-mac*
  (setq dired-use-ls-dired nil)
  (setq mac-command-modifier 'meta)
  (setq mac-option-modifier 'none)
  ;; Make mouse wheel / trackpad scrolling less jerky
  (setq mouse-wheel-scroll-amount '(1
                                    ((shift) . 5)
                                    ((control))))
  (dolist (multiple '("" "double-" "triple-"))
    (dolist (direction '("right" "left"))
      (global-set-key (read-kbd-macro (concat "<" multiple "wheel-" direction ">")) 'ignore)))
      (global-set-key (kbd "M-`") 'ns-next-frame)
      (global-set-key (kbd "M-h") 'ns-do-hide-emacs)
      (global-set-key (kbd "M-˙") 'ns-do-hide-others))

;; Sessions
(use-package desktop
  :custom
  (desktop-dirname user-emacs-directory)
  (desktop-base-file-name "desktop")
  (desktop-base-lock-name "desktop.lock")
  (desktop-restore-frames t)
  (desktop-restore-reuses-frames t)
  (desktop-restore-in-current-display t)
  (desktop-restore-forces-onscreen t)
  (desktop-globals-to-save
   '((magit-revision-history   . 50)
     (minibuffer-history       . 50)
     (ivy-history . 100)))
  :init
  (desktop-save-mode 1))

(setq-default history-length 1000)
(add-hook 'after-init-hook 'savehist-mode)

;; Custom file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;; (when (file-exists-p custom-file)
;;   (load custom-file))

(require 'init-user-local nil t)

;; Seem to have issues with this lagging
(blink-cursor-mode 0)

(winner-mode +1)

;; Avoid littering filesystem with backup files
(setq
 make-backup-files nil
 auto-save-default nil
 create-lockfiles nil)

;; Load themes
(setq custom-safe-themes t)

(use-package modus-themes
  :ensure t
  :config
  (load-theme 'modus-operandi))

;; Start emacsclient
(add-hook 'after-init-hook
          (lambda ()
            (require 'server)
            (unless (server-running-p)
              (server-start))))

;;; init.el ends here
