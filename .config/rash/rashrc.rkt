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

    (readline-prompt #{prompt show (if (exn:fail? retval) 1 0) insert |> port->bytes})))

(define-simple-pipeline-alias nv nvim)
