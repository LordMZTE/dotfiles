; extends

;; Keywords
(("async" @keyword) (#set! conceal "ﰦ"))
(("const" @keyword) (#set! conceal ""))
(("else" @keyword) (#set! conceal ""))
(("enum" @keyword) (#set! conceal ""))
(("fn" @keyword) (#set! conceal "λ"))
(("for" @keyword) (#set! conceal "ﳁ"))
(("if" @keyword) (#set! conceal ""))
(("pub" @keyword) (#set! conceal ""))
(("return" @keyword) (#set! conceal ""))
(("struct" @keyword) (#set! conceal ""))
(("switch" @keyword) (#set! conceal ""))
(("var" @keyword) (#set! conceal ""))
(("while" @keyword) (#set! conceal "ﯩ"))
(("try" @keyword) (#set! conceal ""))
(("comptime" @keyword) (#set! conceal "ﳼ"))

;; Functions
((BUILTINIDENTIFIER) @include
  (#any-of? @include "@import" "@cImport")
  (#set! conceal ""))

;; Common Variables
(((IDENTIFIER) @variable
 (#eq? @variable "self"))
    (#set! conceal ""))

;; Operators
(("&" @operator) (#set! conceal ""))
(("*" @operator) (#set! conceal ""))
(("=>" @operator) (#set! conceal "ﰲ"))
(("?" @operator) (#set! conceal ""))
