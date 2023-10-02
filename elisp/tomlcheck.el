;;; flymake-tomlcheck.el --- TOML linter with tomlcheck  -*- lexical-binding: t; -*-

;; replace /PATH/TO/TOMLCHECK.PY with actual path to tomlcheck.py
;; the contents should be:

;;;;;;;;;;;; tomlcheck.py
;; #!/usr/bin/env python3
;; # usage: python3 tomlcheck.py < something.toml
;; # pip3 install --user toml

;; # emacs regex:  "^\\(?3:[^(]*\\)(line \\(?1:[0-9]+\\) column \\(?2:[0-9]+\\) char [0-9]+)$"
;; # (match-string 1) = line, (match-string 2) = col, (match-string 3) = msg

;; import sys
;; import toml

;; try:
;;     toml.load(sys.stdin)
;; except Exception as e:
;;     print(e)
;;;;;;;;;;;;;;;;;;

(require 'flymake)

(defgroup flymake-tomlcheck nil
  "Tomlcheck backend for Flymake."
  :prefix "flymake-tomlcheck-"
  :group 'tools)

(defcustom flymake-tomlcheck-arguments
  nil
  "A list of strings to pass to the tomlcheck program as arguments."
  :type '(repeat (string :tag "Argument")))

(defvar-local flymake-tomlcheck--proc nil)

(defun flymake-tomlcheck (report-fn &rest _args)
  "Flymake backend for tomlcheck report using REPORT-FN."
  (when (process-live-p flymake-tomlcheck--proc)
    (kill-process flymake-tomlcheck--proc)
    (setq flymake-tomlcheck--proc nil))
  (let ((source (current-buffer)))
    (save-restriction
      (widen)
      (setq
       flymake-tomlcheck--proc
       (make-process
        :name "flymake-tomlcheck" :noquery t :connection-type 'pipe
        :buffer (generate-new-buffer " *flymake-tomlcheck*")
        :command `("/usr/bin/python" "/PATH/TO/TOMLCHECK.PY")
        :sentinel
        (lambda (proc _event)
          (when (eq 'exit (process-status proc))
            (unwind-protect
                (if (with-current-buffer source (eq proc flymake-tomlcheck--proc))
                    (with-current-buffer (process-buffer proc)
                      (goto-char (point-min))
                      (let ((diags))
                        (while (search-forward-regexp "^\\(?3:[^(]*\\)(line \\(?1:[0-9]+\\) column \\(?2:[0-9]+\\) char [0-9]+)$" nil t)
                          (let ((region (flymake-diag-region source (string-to-number (match-string 1)) (string-to-number (match-string 2))))
                                (error-type (match-string 3)))
                            ;; expect `region' to only have 2 values (start . end)
			    (when (and (car region) (cdr region))
                              (push (flymake-make-diagnostic source
                                                             (car region)
                                                             (cdr region)
							     :error
                                                             (match-string 3))
				    diags))))
                        (funcall report-fn (reverse diags))))
                  (flymake-log :warning "Canceling obsolete check %s"
                               proc))
              (kill-buffer (process-buffer proc)))))))
      (process-send-region flymake-tomlcheck--proc (point-min) (point-max))
      (process-send-eof flymake-tomlcheck--proc))))

;;;###autoload
(defun flymake-tomlcheck-setup ()
  "Enable tomlcheck flymake backend."
  (make-variable-buffer-local 'flymake-diagnostic-functions)
  (add-hook 'flymake-diagnostic-functions #'flymake-tomlcheck nil t))

(provide 'flymake-tomlcheck)
;;; flymake-tomlcheck.el ends here
