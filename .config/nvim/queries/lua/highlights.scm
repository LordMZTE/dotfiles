; extends

;; Keywords
(("else" @keyword) (#set! conceal ""))
(("for" @keyword) (#set! conceal "ﳁ"))
(("function" @keyword) (#set! conceal "λ"))
(("if" @keyword) (#set! conceal ""))
(("local" @keyword) (#set! conceal ""))
(("return" @keyword) (#set! conceal ""))
(("while" @keyword) (#set! conceal "ﯩ"))

;; Functions
((function_call name: (identifier) @function (#eq? @function "require")) (#set! conceal ""))
