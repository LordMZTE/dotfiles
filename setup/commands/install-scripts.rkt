#lang racket
(require "../common.rkt")
(provide run)

(define (run)
  (define (bin-path bin)
    (build-path (output-bin-path) "bin" bin))

  (generate-cgopt-json)

  ;; Symlink interpreted scripts
  (install-link "scripts/map-touch-display.rkt" (bin-path "map-touch-display"))
  (install-link "scripts/startriver.sh" (bin-path "startriver"))
  (install-link "scripts/update-nvim-plugins.rkt" (bin-path "update-nvim-plugins"))
  (install-link "scripts/use-country-mirrors.sh" (bin-path "use-country-mirrors"))
  (install-link "scripts/videos-duration.sh" (bin-path "videos-duration"))

  ;; Compile scripts
  (install-zig "scripts/alecor")
  (install-zig "scripts/hyprtool")
  (install-rust "scripts/i3status")
  (install-zig "scripts/mzteinit")
  (install-zig "scripts/openbrowser")
  (install-zig "scripts/pacmanxfer")
  (install-zig "scripts/playtwitch")
  (install-zig "scripts/prompt")
  (install-zig "scripts/randomwallpaper")
  (install-zig "scripts/vinput")
  (install-zig "scripts/withjava")
  (install-zig "scripts/wlbg")

  (install-roswell "scripts/launchmenu.ros")
  (install-roswell "scripts/playvid.ros")
  null)
