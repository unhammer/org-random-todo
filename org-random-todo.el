;;; org-random-todo.el --- notify of random TODO's

;; Copyright (C) 2013 Kevin Brubeck Unhammer

;; Author: Kevin Brubeck Unhammer <unhammer+dill@mm.st>
;; Version: 0.1
;; Package-Requires: ((org-mode "7.9.3f"))
;; Keywords: org todo notification

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Show a random TODO from your org-agenda-files every so often.
;; Requires org-element, which was added fairly recently to org-mode
;; (tested with org-mode version 7.9.3f).

;;; Code:

(require 'org-element)
(require 'cl)
(unless (fboundp 'cl-mapcan) (defalias 'cl-mapcan 'mapcan))

(defvar org-random-todo-files nil
  "Files to grab TODO items from (if nil, use
`org-agenda-files').")

(defvar org-random-todo-list-cache nil)
(defun org-random-todo-list-cache ()
  (setq org-random-todo-list-cache
	(cl-mapcan
	 (lambda (file)
	   (when (file-exists-p file)
	     (with-current-buffer (org-get-agenda-file-buffer file)
	       (org-element-map (org-element-parse-buffer)
				'headline
				(lambda (hl)
				  (when (org-element-property :todo-keyword hl)
				    (cons file
					  (org-element-property :raw-value hl))))))))
	 (or org-random-todo-files org-agenda-files))))

(defvar org-random-todo-notification-id nil)
(defun org-random-todo ()
  "Show a random TODO notification from your
`org-random-todo-files'. Run `org-random-todo-list-cache' if TODO's are
out of date."
  (interactive)
  (unless org-random-todo-list-cache
    (org-random-todo-list-cache))
  (with-temp-buffer
    (let ((todo (nth (random (length org-random-todo-list-cache))
		     org-random-todo-list-cache)))
      (message "%s: %s" (file-name-base (car todo)) (cdr todo))
      (setq org-random-todo-notification-id
	    (notifications-notify :title (file-name-base (car todo))
				  :body (cdr todo)
				  :timeout 4
				  :replaces-id org-random-todo-notification-id)))))

(defvar org-random-todo-how-often 600
  "After this many seconds, run `org-random-todo' to show a
random TODO notification.")
(run-with-timer org-random-todo-how-often
		org-random-todo-how-often
		'org-random-todo)

(defvar org-random-todo-cache-idletime 600
  "After being idle this many seconds, update
`org-random-todo-cache'.")
(run-with-idle-timer org-random-todo-cache-idletime
		     'on-each-idle
		     'org-random-todo-list-cache)

(provide 'org-random-todo)
