(defun mo-term-git-mode--get-branch ()
  ;;(vc-call-backend 'git 'mode-line-string ".") ; doesn't work
  ;;(let ((branches (vc-git-branches)))
  (let ((branches (vc-call-backend 'git 'branches)))
    (when branches (car branches))))

(define-minor-mode mo-term-git-mode
  "show current branch in modeline in terminal-modes"
  :lighter (:eval (let ((git-branch (mo-term-git-mode--get-branch)))
		    (if git-branch
			(format " git:%s" git-branch)
		      ""))))

(add-hook 'term-mode-hook 'mo-term-git-mode)
