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
  (mklink "scripts/startriver.sh" (bin-path "startriver"))
  (mklink "scripts/update-nvim-plugins.rkt" (bin-path "update-nvim-plugins"))
  (mklink "scripts/use-country-mirrors.sh" (bin-path "use-country-mirrors"))
  (mklink "scripts/videos-duration.sh" (bin-path "videos-duration"))

  ;; Compile scripts
  (install-zig "scripts/alecor")
  (install-zig "scripts/hyprtool")
  (install-rust "scripts/i3status")
  (install-zig "scripts/mzteinit")
  (install-zig "scripts/openbrowser")
  (install-zig "scripts/playtwitch")
  (install-zig "scripts/prompt")
  (install-zig "scripts/randomwallpaper")
  (install-zig "scripts/vinput")
  (install-zig "scripts/withjava")

  (install-roswell "scripts/launchmenu.ros")
  (install-roswell "scripts/playvid.ros")
  null)
