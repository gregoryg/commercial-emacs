;;; dig.el --- Domain Name System dig interface  -*- lexical-binding:t -*-

;; Copyright (C) 2000-2022 Free Software Foundation, Inc.

;; Author: Simon Josefsson <simon@josefsson.org>
;; Keywords: DNS BIND dig comm

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

;; This provides an interface for "dig".
;;
;; For interactive use, try `M-x dig' and type a hostname.  Use `q' to
;; quit dig buffer.
;;
;; For use in Emacs Lisp programs, call `dig-invoke' and use
;; `dig-extract-rr' to extract resource records.

;;; Code:

(defgroup dig nil
  "Dig configuration."
  :group 'comm)

(defcustom dig-program "dig"
  "Name of dig (domain information groper) binary."
  :type 'file)

(defcustom dig-program-options nil
  "Options for the dig program."
  :type '(repeat string)
  :version "26.1")

(defcustom dig-dns-server nil
  "DNS server to query.
If nil, use system defaults."
  :type '(choice (const :tag "System defaults")
		 string))

(defcustom dig-font-lock-keywords
  '(("^;; [A-Z]+ SECTION:" 0 font-lock-keyword-face)
    ("^;;.*" 0 font-lock-comment-face)
    ("^; <<>>.*" 0 font-lock-type-face)
    ("^;.*" 0 font-lock-function-name-face))
  "Default expressions to highlight in dig mode."
  :type 'sexp)

(defun dig-invoke (domain &optional
                       query-type query-class query-option
                       dig-option server)
  "Call dig with given arguments and return buffer containing output.
DOMAIN is a string with a DNS domain.  QUERY-TYPE is an optional
string with a DNS type.  QUERY-CLASS is an optional string with a DNS
class.  QUERY-OPTION is an optional string with dig \"query options\".
DIG-OPTION is an optional string with parameters for the dig program.
SERVER is an optional string with a domain name server to query.

Dig is an external program found in the BIND name server distribution,
and is a commonly available debugging tool."
  (let (buf cmdline)
    (setq buf (generate-new-buffer "*dig output*"))
    (if dig-option (push dig-option cmdline))
    (if query-option (push query-option cmdline))
    (if query-class (push query-class cmdline))
    (if query-type (push query-type cmdline))
    (push domain cmdline)
    (if server (push (concat "@" server) cmdline)
      (if dig-dns-server (push (concat "@" dig-dns-server) cmdline)))
    (apply #'call-process dig-program nil buf nil
           (append dig-program-options cmdline))
    buf))

(defun dig-extract-rr (domain &optional type class)
  "Extract resource records for DOMAIN, TYPE and CLASS from buffer.
Buffer should contain output generated by `dig-invoke'."
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward
	 (concat domain "\\.?[\t ]+[0-9wWdDhHmMsS]+[\t ]+"
		 (upcase (or class "IN")) "[\t ]+" (upcase (or type "A")))
	 nil t)
	(let (b e)
	  (end-of-line)
	  (setq e (point))
	  (beginning-of-line)
	  (setq b (point))
	  (when (search-forward " (" e t)
	    (search-forward " )"))
	  (end-of-line)
	  (setq e (point))
	  (buffer-substring b e))
      (and (re-search-forward (concat domain "\\.?[\t ]+[0-9wWdDhHmMsS]+[\t ]+"
				      (upcase (or class "IN"))
				      "[\t ]+CNAME[\t ]+\\(.*\\)$") nil t)
	   (dig-extract-rr (match-string 1) type class)))))

(defun dig-rr-get-pkix-cert (rr)
  (let (b e str)
    (string-match "[^\t ]+[\t ]+[0-9wWdDhHmMsS]+[\t ]+IN[\t ]+CERT[\t ]+\\(1\\|PKIX\\)[\t ]+[0-9]+[\t ]+[0-9]+[\t ]+(?" rr)
    (setq b (match-end 0))
    (string-match ")" rr)
    (setq e (match-beginning 0))
    (setq str (substring rr b e))
    (while (string-match "[\t \n\r]" str)
      (setq str (replace-match "" nil nil str)))
    str))

(defvar-keymap dig-mode-map
  "g" nil
  "q" #'dig-exit)

(define-derived-mode dig-mode special-mode "Dig"
  "Major mode for displaying dig output."
  (buffer-disable-undo)
  (setq-local font-lock-defaults '(dig-font-lock-keywords t))
  ;; FIXME: what is this for??  --Stef M
  (font-lock-ensure-keywords))

(defun dig-exit ()
  "Quit dig output buffer."
  (interactive nil dig-mode)
  (quit-window t))

;;;###autoload
(defun dig (domain &optional
		   query-type query-class query-option dig-option server)
  "Query addresses of a DOMAIN using dig.
See `dig-invoke' for an explanation for the parameters.
When called interactively, DOMAIN is prompted for.

If given a \\[universal-argument] prefix, also prompt \
for the QUERY-TYPE parameter.

If given a \\[universal-argument] \\[universal-argument] \
prefix, also prompt for the SERVER parameter."
  (interactive
   (list (let ((default (ffap-machine-at-point)))
           (read-string (format-prompt "Host" default) nil nil default))
         (and current-prefix-arg
              (read-string "Query type: "))))
  (when (and (numberp (car current-prefix-arg))
             (>= (car current-prefix-arg) 16))
    (let ((serv (read-from-minibuffer "Name server: ")))
      (when (not (equal serv ""))
        (setq server serv))))
  (pop-to-buffer-same-window
   (dig-invoke domain query-type query-class query-option dig-option server))
  (goto-char (point-min))
  (and (search-forward ";; ANSWER SECTION:" nil t)
       (forward-line))
  (dig-mode))

(defun dig-query (domain &optional
                         query-type query-class query-option dig-option server)
  "Query addresses of a DOMAIN using dig.
It works by calling `dig-invoke' and `dig-extract-rr'.
Optional arguments are passed to `dig-invoke' and `dig-extract-rr'.
Returns nil for domain/class/type queries that result in no data."
  (let ((buffer (dig-invoke domain query-type query-class
                            query-option dig-option server)))
    (when buffer
      (pop-to-buffer-same-window buffer)
      (let ((digger (dig-extract-rr domain query-type query-class)))
        (kill-buffer buffer)
        digger))))

(define-obsolete-function-alias 'query-dig #'dig-query "29.1")

(provide 'dig)

;;; dig.el ends here
