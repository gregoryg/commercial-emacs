;;; tree-sitter.el --- tree-sitter utilities -*- lexical-binding: t -*-

;; Copyright (C) 2021 Free Software Foundation, Inc.

;; This file is NOT part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(defgroup tree-sitter
  nil
  "Tree-sitter is an incremental parser."
  :group 'tools)

(defcustom tree-sitter-mode-alist
  '((c++-mode . "cpp")
    (rust-mode . "rust")
    (sh-mode . "bash")
    (c-mode . "c")
    (go-mode . "go")
    (html-mode . "html")
    (java-mode . "java")
    (js-mode . "javascript")
    (python-mode . "python")
    (ruby-mode . "ruby"))
  "Map prog-mode to tree-sitter grammar."
  :type '(alist :key-type (symbol :tag "Prog mode")
                :value-type (string :tag "Tree-sitter symbol"))
  :risky t
  :version "28.1")

;;; Node API supplement


;;; Query API suuplement

;;; Language API supplement

;;; Range API supplement

;;; Indent

;;; Debugging

(defun tree-sitter-change-mode ()
  (when (and (not (minibufferp (current-buffer)))
             major-mode
             (derived-mode-p 'prog-mode))
    (setq tree-sitter-buffer-state (tree-sitter-create (current-buffer) major-mode))))

(define-minor-mode tree-sitter-mode
  "Tree-sitter minor mode."
  :lighter " TS"
  (when (or noninteractive (eq (aref (buffer-name) 0) ?\s))
    (setq tree-sitter-mode nil))
  (if tree-sitter-mode
      (progn
        (add-hook 'after-change-major-mode-hook 'tree-sitter-change-mode nil t)
        (tree-sitter-change-mode))
    (remove-hook 'after-change-major-mode-hook 'tree-sitter-change-mode t)))

(defcustom tree-sitter-global-modes t
  "Modes for which tree-sitter mode is automagically turned on.
If nil, means no modes have tree-sitter mode automatically turned
on.  If t, all modes that support tree-sitter mode have it
automatically turned on.  If a list, it should be a list of
`major-mode' symbol names for which tree-sitter mode should be
automatically turned on.  The sense of the list is negated if it
begins with `not'.  For example:
 (c-mode c++-mode)
means that tree-sitter mode is turned on for buffers in C and C++ modes only."
  :type '(choice (const :tag "none" nil)
		 (const :tag "all" t)
		 (set :menu-tag "mode specific" :tag "modes"
		      :value (not)
		      (const :tag "Except" not)
		      (repeat :inline t (symbol :tag "mode"))))
  :group 'tree-sitter)

(defun turn-on-tree-sitter ()
  (when (cond ((eq tree-sitter-global-modes t)
	       t)
	      ((eq (car-safe tree-sitter-global-modes) 'not)
	       (not (memq major-mode (cdr tree-sitter-global-modes))))
	      (t
               (memq major-mode tree-sitter-global-modes)))
    (let (inhibit-quit)
      (tree-sitter-mode))))

(define-globalized-minor-mode global-tree-sitter-mode
  tree-sitter-mode turn-on-tree-sitter
  :initialize 'custom-initialize-delay
  :init-value (and (not noninteractive) (not emacs-basic-display))
  :group 'tree-sitter
  :version "28.1")

(provide 'tree-sitter)

;;; tree-sitter.el ends here
