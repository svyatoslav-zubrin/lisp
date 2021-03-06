;;; sic.el --- simple IMAP client

;; Copyright (C) 2002  Patware Unc.

;; Author: Patrick Anderson <patware@freeshell.org>
;; Keywords: mail

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;;; Version -.5 pre Alpha

;;; Commentary

;; try M-x sic-connect RET
;; enter the server name RET
;; enter the port (probably 143) RET
;; press s to send a request to the server
;;   make the first request a login as:
;;     login someusername somepassword RET
;; now press g to revert the buffer (to show the status of the account)
;; press l to list the titles of the most recent messages
;;   in the 'list' screen:
;;     TAB and shift-TAB moves between messages
;;     RET or mouse-2 retreives that message
;;     d marks that message for deletion
;;     u unmarks that message for deletion
;;     x expunges marked messages
;; C-h m for keyboard help
;; C-x k RET to rid yourself of this abomination

;;; Code

(require 'interpreter-minor)

(defun sic-follow ()
  (sic-send (concat "fetch " (current-word) " rfc822")))

(im-make-mode sic "simple imap client" "\\(^\* \\)\\([0-9]+\\)" sic-follow)

(define-key sic-mode-map [(c)] 'sic-connect)

(define-key sic-mode-map [(d)]
  (lambda () (interactive)
	 (sic-send (concat "store " (current-word) " +flags (\\deleted)"))))

(define-key sic-mode-map [(u)]
  (lambda () (interactive)
	 (sic-send (concat "store " (current-word) " -flags (\\deleted)"))))

(define-key sic-mode-map [(x)]
  (lambda () (interactive)
	 (sic-send "expunge")))

(define-key sic-mode-map [(g)] 'sic-revert)
(defun sic-revert ()
  (interactive)
  (sic-send "select inbox"))

(define-key sic-mode-map [(l)] 'sic-list)
(defun sic-list ()
  (interactive)
  (sic-update-exists)
  (sic-send (concat "fetch " (int-to-string (- sic-exists 5))  ":" (int-to-string sic-exists) " (flags rfc822.header.lines (subject from))"))
  (goto-char (point-min)))

(define-key sic-mode-map [(s)] 'sic-send)


(defgroup sic nil "simple IMAP client" :group 'mail)
(defcustom sic-host "imap.somewhere.org" "imap server")
(defcustom sic-update-interval 240 "seconds between updates")

(defvar sic-exists nil)

(defvar sic-connection nil) ;todo: should be list of processes

(defun sic-update-exists ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
	(if (re-search-forward "\\* \\([0-9]*\\) EXISTS" nil t)
		(setq sic-exists (string-to-int (match-string 1))))))

(defun sic-connect (host port)
  (interactive "sHost: \nnPort (probably 143): ")
  (let ((buf (get-buffer-create (concat "*sic "host ":" (int-to-string port) "*"))))
	(setq sic-connection (open-network-stream "sic-connection" buf host port)) ;todo broken interactive number
	(switch-to-buffer buf)
	(erase-buffer)
	(sic-mode)))
; 	(run-at-time sic-update-interval sic-update-interval 'sic-revert)))

(defun sic-send (msg)
  (interactive "sMessage: ")
  (with-current-buffer (process-buffer sic-connection)
	(erase-buffer)
	(beginning-of-buffer)
	(process-send-string sic-connection (concat "a "msg "\r\n"))))

(provide 'sic)
;;; sic.el ends here