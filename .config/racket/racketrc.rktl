(current-print (λ (x)
                 (cond
                   [(void? x) #f]
                   ;; Also show fractions as decimals.
                   [(and (rational? x) (not (integer? x))) (printf "~a = ~a" x (exact->inexact x))]
                   [else (pretty-print x)])))
