#lang rash
(require
  racket/port
  rash/private/rashrc-lib
  readline/pread)

(current-prompt-function
  (λ ()
    (readline-prompt #{prompt show 0 insert |> port->bytes})))
