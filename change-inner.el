;;; change-inner.el --- Change contents based on semantic units  -*- lexical-binding: t -*-

;; Copyright (C) 2012 Magnar Sveen <magnars@gmail.com>
;;               2022 Tony Zorman <soliditsallgood@mailbox.org>

;; Author: Magnar Sveen <magnars@gmail.com> (https://github.com/magnars/change-inner.el)
;;         Tony Zorman <soliditsallgood@mailbox.org> (https://github.com/slotThe/change-inner)
;; Version: 0.3.0
;; URL: https://github.com/slotThe/change-inner
;; Keywords: convenience, extensions
;; Package-Requires: ((puni "0"))

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; See the README.md.

;;; Code:

(require 'puni)
(eval-when-compile (require 'cl-lib))

(defun change-inner--puni-ignore-errors (oldfun)
  "Wrap OLDFUN in `ignore-errors'"
  (ignore-errors (funcall oldfun)))
(advice-add 'puni-bounds-of-sexp-at-point :around
  #'change-inner--puni-ignore-errors)

(cl-defun change-inner--work (&key search-for mode)
  "Delete (the innards of) a semantic unit.
Takes a char, like ( or \", and kills the first ancestor semantic
unit starting with that char. The unit must be recognisable to
`puni'.

SEARCH-FOR is the opening delimiter to search for: if this is
nil, prompt for one. MODE is whether to kill the whole
region (`outer'), or just the innards of it (any other value,
including nil)."
  (cl-labels
      ((expand (char &optional forward)
         "Expand until we encompass the whole expression."
         (let* ((char (or char
                          (char-to-string
                           (read-char (format "Kill %s:"
                                              (symbol-name
                                               (or mode 'inner)))))))
                (q-char (regexp-quote char))
                (starting-point (point)))
           ;; Try to find a region.
           (puni-expand-region)
           (when (> (point) (mark))
             (exchange-point-and-mark))
           (while (and (not (= (point) (point-min)))
                       (not (looking-at q-char))
                       (ignore-errors (or (puni-expand-region) t))))
           ;; If we haven't found one yet, initiate a forward search and
           ;; try again—once.
           (when (not (looking-at q-char))
             (goto-char starting-point)
             (deactivate-mark)
             (if forward
                 (error "Couldn't find any expansion starting with %S" char)
               (search-forward char (pos-eol 2))
               (expand char 'forward))))))
    (expand search-for)

    (let ((rb (region-beginning))
          (re (region-end)))
      (if (eq mode 'outer)
          (kill-region rb re)         ; Kill everything
        ;; If we want to delete inside the expression, fall back to `puni'.
        ;; This circumvents having to call `er--expand-region-1' and then
        ;; `er/contract-region' in some vaguely sensical order, and hoping
        ;; to recover the inner expansion from that.
        ;; Addresses ghub:magnars/change-inner.el#5
        (let* ((insides (progn (goto-char (1+ rb))
                               (puni-bounds-of-list-around-point)))
               (olen (- (car insides) rb))  ; Length of opening delimiter
               (clen (- re (cdr insides)))) ; Length of closing delimiter
          (kill-region (+ rb olen) (- re clen)))))))

;;;###autoload
(defun change-inner ()
  "Change the insides of a semantic unit.
Emulates vim's `ci'; see `change-inner--work' for more
information."
  (interactive)
  (change-inner--work))

;;;###autoload
(defun change-inner-outer ()
  "Change the outsides of a semantic unit.
Emulates vim's `co'; see `change-inner--work' for more
information."
  (interactive)
  (change-inner--work :mode 'outer))

;;;###autoload
(defun change-inner-around (&optional arg)
  "Change the insides or outsides of a semantic unit.
If ARG is given, change the outsides; otherwise, do the same for
the insides. See `change-inner--work' for more information."
  (interactive "P")
  (if arg (change-inner-outer) (change-inner)))

(provide 'change-inner)

;;; change-inner.el ends here
