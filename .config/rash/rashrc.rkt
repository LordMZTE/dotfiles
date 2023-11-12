#lang rash
(require
  racket/port
  rash/private/rashrc-lib
  readline/pread)

(provide nv)

(current-prompt-function
  (λ (#:last-return-value retval)
    (unless (void? retval)
      (display ((current-rash-top-level-print-formatter) retval)))

    (parameterize ([current-environment-variables (environment-variables-copy (current-environment-variables))])
      (putenv "MZPROMPT_STATUS" (if (exn:fail? retval) "1" "0"))
      (putenv "MZPROMPT_FISH_MODE" "insert")
      (putenv "MZPROMPT_DURATION" "0")
      (putenv "MZPROMPT_JOBS" "0")
      (readline-prompt #{prompt show |> port->bytes}))))

(define-simple-pipeline-alias nv nvim)
