(current-print (λ (x)
                 (cond
                   [(void? x) #f]
                   ;; Also show fractions as decimals.
                   [(and (number? x) (exact? x) (not (exact-integer? x))) (printf "~a = ~a" x (exact->inexact x))]
                   [else (pretty-print x)])))
