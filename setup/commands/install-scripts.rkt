#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (define (bin-path bin)
    (build-path (output-bin-path) "bin" bin))

  (generate-cgopt-json)

  ;; Symlink interpreted scripts
  (install-link "scripts/brightness.rkt" (bin-path "brightness"))
  (install-link "scripts/map-touch-display.rkt" (bin-path "map-touch-display"))
  (install-link "scripts/typstwatch.sh" (bin-path "typstwatch"))
  (install-link "scripts/videos-duration.sh" (bin-path "videos-duration"))

  ;; Compiled scripts
  (install-zig "scripts/hyprtool")
  (install-rust "scripts/i3status")
  (install-zig "scripts/mzteinit")
  (install-zig "scripts/mzteriver")
  (install-zig "scripts/openbrowser")
  (install-zig "scripts/playvid")
  (install-zig "scripts/prompt")
  (install-zig "scripts/randomwallpaper")
  (install-zig "scripts/vinput")
  (install-zig "scripts/withjava")
  (install-zig "scripts/wlbg")

  (install-roswell "scripts/launchmenu.ros")
  null)
