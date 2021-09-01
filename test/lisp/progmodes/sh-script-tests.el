;;; sh-script-tests.el --- Tests for sh-script.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Free Software Foundation, Inc.

;; This file is part of GNU Emacs.

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

(require 'sh-script)
(require 'ert)

(ert-deftest test-sh-script-indentation ()
  (with-temp-buffer
    (insert "relative-path/to/configure --prefix=$prefix\\
             --with-x")
    (shell-script-mode)
    (goto-char (point-min))
    (forward-line 1)
    (indent-for-tab-command)
    (should (equal
             (buffer-substring-no-properties (point-min) (point-max))
             "relative-path/to/configure --prefix=$prefix\\
			   --with-x")))
  (with-temp-buffer
    (insert "${path_to_root}/configure --prefix=$prefix\\
             --with-x")
    (shell-script-mode)
    (goto-char (point-min))
    (forward-line 1)
    (indent-for-tab-command)
    (should (equal
             (buffer-substring-no-properties (point-min) (point-max))
             "${path_to_root}/configure --prefix=$prefix\\
			  --with-x"))))

;;; sh-script-tests.el ends here