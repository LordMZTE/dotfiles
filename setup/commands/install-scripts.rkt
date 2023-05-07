#lang racket
(require "../common.rkt")
(provide run)

(define-logging mklink
                (λ (from to)
                  (with-handlers ([exn:fail? (const #f)]) (delete-file to))
                  (make-file-or-directory-link (normalize-path from) to)))

(define (run)
  ;; Symlink interpreted scripts
  (mklink "scripts/map-touch-display.rkt" (build-path (output-bin-path) "bin" "map-touch-display"))
  (mklink "scripts/playvid.rkt" (build-path (output-bin-path) "bin" "playvid"))
  (mklink "scripts/start-joshuto.sh" (build-path (output-bin-path) "bin" "start-joshuto"))
  (mklink "scripts/startriver.sh" (build-path (output-bin-path) "bin" "startriver"))
  (mklink "scripts/update-nvim-plugins.rkt"
          (build-path (output-bin-path) "bin" "update-nvim-plugins"))
  (mklink "scripts/withjava.sh" (build-path (output-bin-path) "bin" "withjava"))

  ;; Compile Zig scripts
  (install-zig "scripts/mzteinit")
  (install-zig "scripts/openbrowser")
  (install-zig "scripts/playtwitch")
  (install-zig "scripts/prompt")
  (install-zig "scripts/randomwallpaper")
  (install-zig "scripts/vinput")
  null)
