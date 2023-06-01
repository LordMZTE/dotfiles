#lang racket
(require "../common.rkt")
(provide run)

(define-logging mklink
  (λ (from to)
    (with-handlers ([exn:fail? (const #f)]) (delete-file to))
    (make-file-or-directory-link (normalize-path from) to)))

(define (run)
  (define (bin-path bin)
    (build-path (output-bin-path) "bin" bin))

  (generate-cgopt-json)

  ;; Symlink interpreted scripts
  (mklink "scripts/map-touch-display.rkt" (bin-path "map-touch-display"))
  (mklink "scripts/start-joshuto.sh" (bin-path "start-joshuto"))
  (mklink "scripts/startriver.sh" (bin-path "startriver"))
  (mklink "scripts/update-nvim-plugins.rkt" (bin-path "update-nvim-plugins"))
  (mklink "scripts/withjava.sh" (bin-path "withjava"))

  ;; Compile scripts
  (install-rust "scripts/i3status")
  (install-zig "scripts/mzteinit")
  (install-zig "scripts/openbrowser")
  (install-zig "scripts/playtwitch")
  (install-zig "scripts/prompt")
  (install-zig "scripts/randomwallpaper")
  (install-zig "scripts/vinput")

  (install-roswell "scripts/playvid.ros")
  null)
